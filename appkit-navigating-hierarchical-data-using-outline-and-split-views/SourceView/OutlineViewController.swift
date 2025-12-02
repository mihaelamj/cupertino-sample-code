/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller that contains the NSOutlineView and NSTreeController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

class OutlineViewController: NSViewController,
    							NSTextFieldDelegate, // To respond to the text field's edit sending.
								NSUserInterfaceValidations { // To enable/disable menu items for the outline view.
    // MARK: Constants
    
    struct NameConstants {
        // The default name for added folders and leafs.
        static let untitled = NSLocalizedString("untitled string", comment: "")
        // The places group title.
        static let places = NSLocalizedString("places string", comment: "")
        // The pictures group title.
        static let pictures = NSLocalizedString("pictures string", comment: "")
    }

    struct NotificationNames {
        // A notification when the tree controller's selection changes. SplitViewController uses this.
        static let selectionChanged = "selectionChangedNotification"
    }
    
    // MARK: Outlets
    
    // The data source backing of the NSOutlineView.
    @IBOutlet weak var treeController: NSTreeController!

    @IBOutlet weak var outlineView: OutlineView! {
        didSet {
            // As soon the outline view loads, populate its content tree controller.
            populateOutlineContents()
        }
    }
    
	@IBOutlet private weak var placeHolderView: NSView!
    
    // MARK: Instance Variables
    
    // The observer of the tree controller when its selection changes using KVO.
    private var treeControllerObserver: NSKeyValueObservation?
    
    // The outline view of top-level content. NSTreeController backs this.
    @objc dynamic var contents: [AnyObject] = []
    
  	var rowToAdd = -1 // The addition of a flagged row (for later renaming).
    
    // The directory for accepting promised files.
    lazy var promiseDestinationURL: URL = {
        let promiseDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: promiseDestinationURL, withIntermediateDirectories: true, attributes: nil)
        return promiseDestinationURL
    }()

    private var iconViewController: IconViewController!
    private var fileViewController: FileViewController!
    private var imageViewController: ImageViewController!
    private var multipleItemsViewController: NSViewController!
        
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determine the contextual menu for the outline view.
   		outlineView.customMenuDelegate = self
        
        // Dragging items out: Set the default operation mask so you can drag (copy) items to outside this app, and delete them in the Trash can.
        outlineView?.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
        
        // Register for drag types coming in to receive file promises from Photos, Mail, Safari, and so forth.
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        // You want these drag types: your own type (outline row number), and fileURLs.
		outlineView.registerForDraggedTypes([
      		.nodeRowPasteBoardType, // Your internal drag type, the outline view's row number for internal drags.
            NSPasteboard.PasteboardType.fileURL // To receive file URL drags.
            ])

        /** Disclose the two root outline groups (Places and Pictures) at first launch.
         	With all subsequent launches, the autosave disclosure states determine these disclosure states.
         */
        let defaults = UserDefaults.standard
        let initialDisclosure = defaults.string(forKey: "initialDisclosure")
        if initialDisclosure == nil {
            outlineView.expandItem(treeController.arrangedObjects.children![0])
            outlineView.expandItem(treeController.arrangedObjects.children![1])
            defaults.set("initialDisclosure", forKey: "initialDisclosure")
        }
        
        // Load the icon view controller from the storyboard for later use as your Detail view.
        iconViewController =
            storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
        iconViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the file view controller from the storyboard for later use as your Detail view.
        fileViewController =
            storyboard!.instantiateController(withIdentifier: "FileViewController") as? FileViewController
        fileViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the image view controller from the storyboard for later use as your Detail view.
        imageViewController =
            storyboard!.instantiateController(withIdentifier: "ImageViewController") as? ImageViewController
        imageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the multiple items selected view controller from the storyboard for later use as your Detail view.
        multipleItemsViewController =
            storyboard!.instantiateController(withIdentifier: "MultipleSelection") as? NSViewController
		multipleItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        /** Note: The following makes the outline view appear with gradient background and proper
         	selection to behave like the Finder sidebar, iTunes, and so forth.
         */
        //outlineView.selectionHighlightStyle = .sourceList // But you already do this in the storyboard.
        
        // Set up observers for the outline view's selection, adding items, and removing items.
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.addFolder),
            object: nil)
        NotificationCenter.default.removeObserver(
            self,
        	name: Notification.Name(WindowViewController.NotificationNames.addPicture),
         	object: nil)
        NotificationCenter.default.removeObserver(
            self,
    		name: Notification.Name(WindowViewController.NotificationNames.removeItem),
   			object: nil)
    }
    
    // MARK: OutlineView Setup
    
    // Take the currently selected node and select its parent.
    private func selectParentFromSelection() {
        if !treeController.selectedNodes.isEmpty {
            let firstSelectedNode = treeController.selectedNodes[0]
            if let parentNode = firstSelectedNode.parent {
                // Select the parent.
                let parentIndex = parentNode.indexPath
                treeController.setSelectionIndexPath(parentIndex)
            } else {
                // No parent exists (you are at the top of tree), so make no selection in your outline.
                let selectionIndexPaths = treeController.selectionIndexPaths
                treeController.removeSelectionIndexPaths(selectionIndexPaths)
            }
        }
    }
	
    // The system calls this by drag and drop from the Finder.
    func addFileSystemObject(_ url: URL, indexPath: IndexPath) {
        let node = OutlineViewController.fileSystemNode(from: url)
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        
        if url.isFolder {
            do {
                node.identifier = NSUUID().uuidString
                // It's a folder node, so find its children.
                let fileURLs =
                    try FileManager.default.contentsOfDirectory(at: node.url!,
                                                                includingPropertiesForKeys: [],
                                                                options: [.skipsHiddenFiles])
                // Move indexPath one level deep for insertion.
                let newIndexPath = indexPath
                let finalIndexPath = newIndexPath.appending(0)
                
                addFileSystemObjects(fileURLs, indexPath: finalIndexPath)
            } catch _ {
                // No content at this URL.
            }
        } else {
            // This is just a leaf node, so there aren't any children to insert.
        }
    }

    private func addFileSystemObjects(_ entries: [URL], indexPath: IndexPath) {
        // Sort the array of URLs.
        var sorted = entries
        sorted.sort( by: { $0.lastPathComponent > $1.lastPathComponent })
        
        // Insert the sorted URL array into the tree controller.
        for entry in sorted {
            if entry.isFolder {
                // It's a folder node, so add the folder.
                let node = OutlineViewController.fileSystemNode(from: entry)
                node.identifier = NSUUID().uuidString
                treeController.insert(node, atArrangedObjectIndexPath: indexPath)
                
                do {
                    let fileURLs =
                        try FileManager.default.contentsOfDirectory(at: entry,
                                                                    includingPropertiesForKeys: [],
                                                                    options: [.skipsHiddenFiles])
                    if !fileURLs.isEmpty {
                        // Move indexPath one level deep for insertions.
                        let newIndexPath = indexPath
                        let final = newIndexPath.appending(0)
                        
                        addFileSystemObjects(fileURLs, indexPath: final)
                    }
                } catch _ {
                    // No content at this URL.
                }
            } else {
                // It's a leaf node, so add the leaf.
                addFileSystemObject(entry, indexPath: indexPath)
            }
        }
    }

    private func addGroupNode(_ folderName: String, identifier: String) {
        let node = Node()
        node.type = .container
        node.title = folderName
        node.identifier = identifier
    
        // Insert the group node.
        
        // Get the insertion indexPath from the current selection.
        var insertionIndexPath: IndexPath
        // If there is no selection, add a new group to the end of the content's array.
        if treeController.selectedObjects.isEmpty {
            // There's no selection, so add the folder to the top-level and at the end.
            insertionIndexPath = IndexPath(index: contents.count)
        } else {
            /** Get the index of the currently selected node, then add the number of its children to the path.
                This gives you an index that allows you to add a node to the end of the currently
                selected node's children array.
             */
            insertionIndexPath = treeController.selectionIndexPath!
            if let selectedNode = treeController.selectedObjects[0] as? Node {
                // The user is trying to add a folder on a selected folder, so add the selection to the children.
                insertionIndexPath.append(selectedNode.children.count)
            }
        }
        
        treeController.insert(node, atArrangedObjectIndexPath: insertionIndexPath)
    }
    
    private func addNode(_ node: Node) {
        // Find the selection to insert the node.
        var indexPath: IndexPath
        if treeController.selectedObjects.isEmpty {
            // No selection, so just add the child to the end of the tree.
            indexPath = IndexPath(index: contents.count)
        } else {
            // There's a selection, so insert the child at the end of the selection.
            indexPath = treeController.selectionIndexPath!
            if let node = treeController.selectedObjects[0] as? Node {
                indexPath.append(node.children.count)
            }
        }
        
        // The child to insert has a valid URL, so use its display name as the node title.
        // Take the URL and obtain the display name (nonescaped with no extension).
        if node.isURLNode {
            node.title = node.url!.localizedName
        }
        
        // The user is adding a child node, so tell the controller directly.
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        
        if !node.isDirectory {
        	// For leaf children, select its parent for further additions.
        	selectParentFromSelection()
        }
    }
    
    // MARK: Outline Content
    
    // Unique nodeIDs for the two top-level group nodes.
    static let picturesID = "1000"
    static let placesID = "1001"
    
    private func addPlacesGroup() {
        // Add the Places outline group section.
        // Note that the system shares the nodeID and the expansion restoration ID.
        
        addGroupNode(OutlineViewController.NameConstants.places, identifier: OutlineViewController.placesID)
        
        // Add the Applications folder inside Places.
        let appsURLs = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
        addFileSystemObject(appsURLs[0], indexPath: IndexPath(indexes: [0, 0]))
        
        treeController.setSelectionIndexPath(nil) // Start back at the root level.
    }
    
    // Populate the tree controller from the disk-based dictionary (DataSource.plist).
    private func addPicturesGroup() {
        // Add the Pictures section.
        addGroupNode(OutlineViewController.NameConstants.pictures, identifier: OutlineViewController.picturesID)

        guard let newPlistURL = Bundle.main.url(forResource: "DataSource", withExtension: "plist") else {
            fatalError("Failed to resolve URL for `DataSource.plist` in bundle.")
        }
        do {
            // Populate the outline view with the .plist file content.
            struct OutlineData: Decodable {
                let children: [Node]
            }
            // Decode the top-level children of the outline.
            let plistDecoder = PropertyListDecoder()
            let data = try Data(contentsOf: newPlistURL)
            let decodedData = try plistDecoder.decode(OutlineData.self, from: data)
            for node in decodedData.children {
                // Recursively add further content from the specified node.
                addNode(node)
                if node.type == .container {
                    selectParentFromSelection()
                }
            }
        } catch {
            fatalError("Failed to load `DataSource.plist` in bundle.")
        }
        treeController.setSelectionIndexPath(nil) // Start back at the root level.
    }
    
    private func populateOutlineContents() {
        // Add the Places grouping and its content.
        addPlacesGroup()
        
        // Add the Pictures grouping and its outline content.
        addPicturesGroup()
    }
    
    // MARK: Removal and Addition

    private func removalConfirmAlert(_ itemsToRemove: [Node]) -> NSAlert {
        let alert = NSAlert()
        
        var messageStr: String
        if itemsToRemove.count > 1 {
            // Remove multiple items.
            alert.messageText = NSLocalizedString("remove multiple string", comment: "")
        } else {
            // Remove the single item.
            if itemsToRemove[0].isURLNode {
                messageStr = NSLocalizedString("remove link confirm string", comment: "")
            } else {
                messageStr = NSLocalizedString("remove confirm string", comment: "")
            }
            alert.messageText = String(format: messageStr, itemsToRemove[0].title)
        }
        
        alert.addButton(withTitle: NSLocalizedString("ok button title", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel button title", comment: ""))
        
        return alert
    }
    
    // The system calls this from handleContextualMenu() or the remove button.
    func removeItems(_ itemsToRemove: [Node]) {
        // Confirm the removal operation.
        let confirmAlert = removalConfirmAlert(itemsToRemove)
        confirmAlert.beginSheetModal(for: view.window!) { returnCode in
            if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
                // Remove the specified set of node objects from the tree controller.
                var indexPathsToRemove = [IndexPath]()
                for item in itemsToRemove {
                    if let indexPath = self.treeController.indexPathOfObject(anObject: item) {
                    	indexPathsToRemove.append(indexPath)
                    }
                }
                self.treeController.removeObjects(atArrangedObjectIndexPaths: indexPathsToRemove)
                
                // Remove the current selection after the removal.
                self.treeController.setSelectionIndexPaths([])
            }
        }
    }
    
    // Remove the currently selected items.
    private func removeItems() {
        var nodesToRemove = [Node]()
        
        for item in treeController.selectedNodes {
            if let node = OutlineViewController.node(from: item) {
                nodesToRemove.append(node)
            }
        }
        removeItems(nodesToRemove)
    }
 
/// - Tag: Delete
    // The user chose the Delete menu item or pressed the Delete key.
    @IBAction func delete(_ sender: AnyObject) {
        removeItems()
    }
    
    // The system calls this from handleContextualMenu() or the add group button.
   func addFolderAtItem(_ item: NSTreeNode) {
        // Obtain the base node at the specified outline view's row number, and the indexPath of that base node.
        guard let rowItemNode = OutlineViewController.node(from: item),
            let itemNodeIndexPath = treeController.indexPathOfObject(anObject: rowItemNode) else { return }
    
        // You're inserting a new group folder at the node index path, so add it to the end.
        let indexPathToInsert = itemNodeIndexPath.appending(rowItemNode.children.count)
    
        // Create an empty folder node.
        let nodeToAdd = Node()
        nodeToAdd.title = OutlineViewController.NameConstants.untitled
        nodeToAdd.identifier = NSUUID().uuidString
        nodeToAdd.type = .container
        treeController.insert(nodeToAdd, atArrangedObjectIndexPath: indexPathToInsert)
    
        // Flag the row you're adding (for later renaming).
        rowToAdd = outlineView.row(forItem: item) + rowItemNode.children.count
    }

    // The system calls this from handleContextualMenu() or the add picture button.
    func addPictureAtItem(_ item: Node) {
        // Present an open panel to choose a picture to display in the outline view.
        let openPanel = NSOpenPanel()
        
        // Find a picture to add.
        let locationTitle = item.title
        let messageStr = NSLocalizedString("choose picture message", comment: "")
        openPanel.message = String(format: messageStr, locationTitle)
        openPanel.prompt = NSLocalizedString("open panel prompt", comment: "") // Set the Choose button title.
        openPanel.canCreateDirectories = false
        
        // Allow choosing all kinds of image files.
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [UTType.image]
        } else {
            if let imageTypes = CGImageSourceCopyTypeIdentifiers() as? [String] {
                openPanel.allowedFileTypes = imageTypes
            }
        }
        
        openPanel.beginSheetModal(for: view.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                // Create a leaf picture node.
                let node = Node()
                node.type = .document
                node.url = openPanel.url
                node.title = node.url!.localizedName
                
                // Get the indexPath of the folder you're adding to.
                if let itemNodeIndexPath = self.treeController.indexPathOfObject(anObject: item) {
                    // You're inserting a new picture at the item node index path.
                    let indexPathToInsert = itemNodeIndexPath.appending(IndexPath(index: 0))
                    self.treeController.insert(node, atArrangedObjectIndexPath: indexPathToInsert)
                }
            }
        }
    }
    
    // MARK: Notifications
    
    private func setupObservers() {
        // A notification to add a folder.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addFolder(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.addFolder),
            object: nil)
        
        // A notification to add a picture.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addPicture(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.addPicture),
            object: nil)
        
        // A notification to remove an item.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(removeItem(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.removeItem),
            object: nil)
        
        // Listen to the treeController's selection change so you inform clients to react to selection changes.
        treeControllerObserver =
            treeController.observe(\.selectedObjects, options: [.new]) {(treeController, change) in
                            // Post this notification so other view controllers can react to the selection change.
                            // Interested view controllers are: WindowViewController and SplitViewController.
                            NotificationCenter.default.post(
                                name: Notification.Name(OutlineViewController.NotificationNames.selectionChanged),
                                object: treeController)
                
                            // Save the outline selection state for later when the app relaunches.
                            self.invalidateRestorableState()
        				}
    }
    
    // A notification that the WindowViewController class sends to add a generic folder to the current selection.
    @objc
    private func addFolder(_ notif: Notification) {
        // Add the folder with the "untitled" title.
        let selectedRow = outlineView.selectedRow
        if let folderToAddNode = self.outlineView.item(atRow: selectedRow) as? NSTreeNode {
            addFolderAtItem(folderToAddNode)
        }
        // Flag the row you're adding (for later renaming).
        rowToAdd = outlineView.selectedRow
    }
    
    // A notification that the WindowViewController class sends to add a picture to the selected folder node.
    @objc
    private func addPicture(_ notif: Notification) {
        let selectedRow = outlineView.selectedRow
        
        if let item = self.outlineView.item(atRow: selectedRow) as? NSTreeNode,
            let addToNode = OutlineViewController.node(from: item) {
            	addPictureAtItem(addToNode)
        }
    }
    
    // A notification that the WindowViewController remove button sends to remove a selected item from the outline view.
    @objc
    private func removeItem(_ notif: Notification) {
        removeItems()
    }
    
    // MARK: NSTextFieldDelegate
    
    // For a text field in each outline view item, the user commits the edit operation.
    func controlTextDidEndEditing(_ obj: Notification) {
        // Commit the edit by applying the text field's text to the current node.
        guard let item = outlineView.item(atRow: outlineView.selectedRow),
            let node = OutlineViewController.node(from: item) else { return }
        
        if let textField = obj.object as? NSTextField {
            node.title = textField.stringValue
        }
    }
    
    // MARK: NSValidatedUserInterfaceItem

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(delete(_:)) {
            return !treeController.selectedObjects.isEmpty
        }
        return true
    }

    // MARK: Detail View Management
    
    // Use this to decide which view controller to use as the detail.
    func viewControllerForSelection(_ selection: [NSTreeNode]?) -> NSViewController? {
        guard let outlineViewSelection = selection else { return nil }
        
        var viewController: NSViewController?
        
        switch outlineViewSelection.count {
        case 0:
            // No selection.
            viewController = nil
        case 1:
            // A single selection.
            if let node = OutlineViewController.node(from: selection?[0] as Any) {
                if let url = node.url {
                    // The node has a URL.
                    if node.isDirectory {
                        // It is a folder URL.
                        iconViewController.url = url
                        viewController = iconViewController
                    } else {
                        // It is a file URL.
                        fileViewController.url = url
                        viewController = fileViewController
                    }
                } else {
                    // The node doesn't have a URL.
                    if node.isDirectory {
                        // It is a non-URL grouping of pictures.
                        iconViewController.nodeContent = node
                        viewController = iconViewController
                    } else {
                        // It is a non-URL image document, so load its image.
                        if let loadedImage = NSImage(named: node.title) {
                            imageViewController.fileImageView?.image = loadedImage
                        } else {
                            debugPrint("Failed to load built-in image: \(node.title)")
                        }
                        viewController = imageViewController
                    }
                }
            }
        default:
            // The selection is multiple or more than one.
            viewController = multipleItemsViewController
        }

        return viewController
    }
    
    // MARK: File Promise Drag Handling

    /// The queue for reading and writing file promises.
    lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
}

