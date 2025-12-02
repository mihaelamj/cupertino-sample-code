/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Drag-and-drop support for OutlineViewController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

// Drag-and-drop support, the custom pasteboard type.
extension NSPasteboard.PasteboardType {
    
	// This UTI string needs be a unique identifier.
    static let nodeRowPasteBoardType =
        NSPasteboard.PasteboardType("com.example.apple-samplecode.SourceView.internalNodeDragType")
}

// MARK: -

extension OutlineViewController: NSFilePromiseProviderDelegate {
    
    // MARK: NSFilePromiseProviderDelegate
    
    // Return the name of the promised file.
    
    // The system calls this before completing the drag. Return the base filename.
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        // Default to using "Untitled" for the file.
        var title = NSLocalizedString("untitled string", comment: "")
        
        if let dragURL = NodePasteboardWriter.urlFromFilePromiseProvider(filePromiseProvider) {
            title = dragURL.lastPathComponent // Use the URL for the title.
        } else {
            if let dragName = nameFromFilePromiseProvider(filePromiseProvider) {
                title = dragName + ".png" // Use the name for the title.
            }
        }
        return title
    }
    
    /** The system calls this as the drag finishes. The URL is the full path to write (including the filename).
		Write the promised fiie. You only write out image documents. Be sure to call the completion handler.
 	*/
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        if let dragURL = NodePasteboardWriter.urlFromFilePromiseProvider(filePromiseProvider) {
            // You have a URL for this node.
            if dragURL.isImage {
                // The URL is an image file, so make the copy.
                do {
                    try FileManager.default.copyItem(at: dragURL, to: url)
                } catch let error {
                    handleError(error)
                    completionHandler(error)
                    return
                }
            }
        } else {
            // The dragged node has no URL, so copy the image data to the destination URL.
            
            // It is a non-URL image node (a built-in from the app), so load its image.
            if let dragName = nameFromFilePromiseProvider(filePromiseProvider) {
                if let loadedImage = NSImage(named: dragName) {
                    // Convert the NSImage to Data for writing.
                    if let pngData = loadedImage.pngData() {
                        do {
                            try pngData.write(to: url)
                        } catch let error {
                            handleError(error)
                            completionHandler(error)
                            return
                        }
                    }
                }
            }
        }
		completionHandler(nil)
    }
    
    // The OperationQueue function for handlng file promise dragging.
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }
    
    // MARK: Utilities
    
    // Obtain the filename to promise from the provider.
    func nameFromFilePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider) -> String? {
        var dragName: String?
        // Find the name.
        if let userInfo = filePromiseProvider.userInfo as? [String: Any] {
            dragName = userInfo[NodePasteboardWriter.UserInfoKeys.name] as? String
        }
        return dragName
    }

}

// MARK: -

extension OutlineViewController: NSOutlineViewDataSource {

    // MARK: Drag and Drop
    
    /** This is the start of an internal drag, so decide what kind of pasteboard writer you want:
 		either NodePasteboardWriter or a nonfile promiser writer.
  		The system calls this for each dragged item in the selection.
	*/
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let dragNode = OutlineViewController.node(from: item) else { return nil }
        
        let rowIdx = outlineView.row(forItem: item)
        
        // Check if the dragNode is promisable (no directories or nonimage files).
        var isPromisable = !dragNode.isDirectory
        if let url = dragNode.url {
            isPromisable = url.isImage
        }
        
        if isPromisable {
            // Start by assuming a leaf node is a built-in image (PNG file).
            var nodeFileType: String
            
            if #available(macOS 11.0, *) {
                nodeFileType = UTType.image.identifier
            } else {
                nodeFileType = kUTTypePNG as String
            }
            
            var urlString = ""
            // Find out if the leaf node has a URL. If so, obtain its string value and its type.
            if let url = dragNode.url {
                if url.isImage {
                    nodeFileType = url.fileType
                    urlString = url.absoluteString
                } else {
                    // It's a non-image file, and you don't promise nonimage files.
                    return nil
                }
            }
            
            // Promise to provide image documents to other applications.
            let provider = NodePasteboardWriter(fileType: nodeFileType, delegate: self)
            provider.userInfo = [
                NodePasteboardWriter.UserInfoKeys.row: rowIdx,
                NodePasteboardWriter.UserInfoKeys.url: urlString,
                NodePasteboardWriter.UserInfoKeys.name: dragNode.title
            ]
            return provider
        } else {
            // The node isn't file-promised because it's a directory or a nonimage file.
            let pasteboardItem = NSPasteboardItem()
            
            // Remember the dragged node by its row number for later.
            let propertyList = [NodePasteboardWriter.UserInfoKeys.row: rowIdx]
            pasteboardItem.setPropertyList(propertyList, forType: .nodeRowPasteBoardType)
            return pasteboardItem
        }
    }

    // A utility function to detect if the user is dragging an item into its descendants.
    private func okToDrop(draggingInfo: NSDraggingInfo, locationItem: NSTreeNode?) -> Bool {
        var droppedOntoItself = false
        draggingInfo.enumerateDraggingItems(options: [],
                                            for: outlineView,
                                            classes: [NSPasteboardItem.self],
                                            searchOptions: [:]) { dragItem, _, _ in
      		if let droppedPasteboardItem = dragItem.item as? NSPasteboardItem {
                if let checkItem = self.itemFromPasteboardItem(droppedPasteboardItem) {
                    // Start at the root and recursively search.
                    let treeRoot = self.treeController.arrangedObjects
                    let node = treeRoot.descendant(at: checkItem.indexPath)
                    var parent = locationItem
                    while parent != nil {
                        if parent == node {
                            droppedOntoItself = true
                            break
                        }
                        parent = parent?.parent
                    }
                }
			}
        }
        return !droppedOntoItself
    }
    
    /** The system calls this during a drag over the outline view before the drop occurs.
        The outline view uses it to determine a visual drop target.
        Use this function to specify how to respond to a proposed drop operation.
    */
    func outlineView(_ outlineView: NSOutlineView,
                     validateDrop info: NSDraggingInfo,
                     proposedItem item: Any?, // The place the drop is hovering over.
                     proposedChildIndex index: Int) -> NSDragOperation { // The child index the drop is hovering over.
        var result = NSDragOperation()
        
        guard index != -1, 	// Don't allow dropping on a child.
            	item != nil	// Make sure you have a valid outline view item to drop on.
        else { return result }
        
        // Find the node you're dropping onto.
        if let dropNode = OutlineViewController.node(from: item as Any) {
            // Don't allow dropping into file system objects.
            if !dropNode.isURLNode {
                // The current drop location is inside the container.
                if info.draggingPasteboard.availableType(from: [.nodeRowPasteBoardType]) != nil {
                    // The drag source is from within the outline view.
                    if dropNode.isDirectory {
                        // Check if you're dropping onto yourself.
                        if okToDrop(draggingInfo: info, locationItem: item as? NSTreeNode) {
                            result = .move
                        }
                    } else {
            			result = .move
                    }
                } else if info.draggingPasteboard.availableType(from: [.fileURL]) != nil {
                    // The drag source is from outside this app as a file URL, so a drop means adding a link/reference.
                    result = .link
                } else {
                    // The drag source is from outside this app and is likely a file promise, so it's going to be a copy.
                    result = .copy
                }
            }
        }

        return result
    }
    
    // handleExternalDrops() calls this to drop any dragged-in items from the Finder or another application.
    private func dropURLs(_ urls: [URL], outlineView: NSOutlineView, location: IndexPath, childIndex index: Int) {
        // Don't process an empty URL list.
        guard !urls.isEmpty else { return }
        
        var urlsToDrop = urls
        
        // Sort the array of URLs.
        urlsToDrop.sort( by: { $0.lastPathComponent > $1.lastPathComponent })
        
        // Insert the array into the tree controller.
        for url in urlsToDrop {
            addFileSystemObject(url, indexPath: location)
        }
        
        // Collapse each inserted item.
        var currentIndex = location.dropLast()
        var childLevelIndex = index
        var droppedIndexPaths = [IndexPath]()
        for _ in 0..<urlsToDrop.count {
            currentIndex.append(childLevelIndex)
            treeController.setSelectionIndexPath(currentIndex)
          
            outlineView.collapseItem(treeController.selectedNodes[0], collapseChildren: true)
            childLevelIndex += 1
            
            // Accumulate dropped indexPaths for later.
            droppedIndexPaths.append(currentIndex)
            
            // Reset the current index path for the next iteration.
            currentIndex = currentIndex.dropLast()
        }
        
        // Select all the dropped items.
        treeController.setSelectionIndexPaths(droppedIndexPaths)
    }
    
    // The user is doing an inter-drag drop from outside the app to the outline view.
    private func handleExternalDrops(_ outlineView: NSOutlineView,
                                     draggingInfo: NSDraggingInfo,
                                     dropIndexPath: IndexPath,
                                     childIndex index: Int) {
        /** Note: For applications that send a drag item with type NSFilenamesPboardType,
     		NSPasteboard automatically converts NSFilenamesPboardType into multiple NSURLs as necessary.
        */

        // Look for file promises and URLs.
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]
        
    	// For items dragged from outside the app, you want to search for readable URLs.
        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        
        var droppedURLs = [URL]()
        
        // Process all dropped pasteboard items.
        draggingInfo.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { (draggingItem, _, _) in
            switch draggingItem.item {
        	case let filePromiseReceiver as NSFilePromiseReceiver:
                // The drag item is a file promise (from Photos, Mail, Safari, and so forth).
                // This calls in the promises. So write to - self.destinationURL.
                filePromiseReceiver.receivePromisedFiles(atDestination: self.promiseDestinationURL,
                                                         options: [:],
                                                         operationQueue: self.workQueue) { (fileURL, error) in
                                                    if let error = error {
                                                        self.handleError(error)
                                                    } else {
                                                        OperationQueue.main.addOperation {
                                                            let node = OutlineViewController.fileSystemNode(from: fileURL)
                                                            self.treeController.insert(node, atArrangedObjectIndexPath: dropIndexPath)
                                                        }
                                                    }
     											}
            case let fileURL as URL:
                // The drag item is a URL reference (not a file promise).
                droppedURLs.append(fileURL)
            default: break
            }
        }
        
        // Process all nonpromised URLs.
        dropURLs(droppedURLs, outlineView: outlineView, location: dropIndexPath, childIndex: index)
    }
    
    // The user is doing a drop or intra-app drop within the outline view.
    private func handleInternalDrops(_ outlineView: NSOutlineView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        // Accumulate all drag items and move them to the proper indexPath.
        var itemsToMove = [NSTreeNode]()
        
        draggingInfo.enumerateDraggingItems(options: [],
                                    		for: outlineView,
                                    		classes: [NSPasteboardItem.self],
                                    		searchOptions: [:]) { dragItem, _, _ in
            if let droppedPasteboardItem = dragItem.item as? NSPasteboardItem {
                if let itemToMove = self.itemFromPasteboardItem(droppedPasteboardItem) {
                    itemsToMove.append(itemToMove)
                }
			}
        }
        
   	 	self.treeController.move(itemsToMove, to: indexPath)
    }
    
    /** Accept the drop.
     	The system calls the following function when the user finishes dragging one or more objects.
     	This occurs when the mouse releases over an outline view that allows a drop via the validateDrop method.
        Handle the data from the dragging pasteboard that's dropping onto the outline view.
     
        The param 'index' is the location to insert the data as a child of 'item', and are the values previously set in the validateDrop: method.
     	Note that "targetItem" is an NSTreeNode proxy node.
     */
    func outlineView(_ outlineView: NSOutlineView,
                     acceptDrop info: NSDraggingInfo,
                     item targetItem: Any?,
                     childIndex index: Int) -> Bool {
        // Find the index path to insert the dropped objects.
        if let dropIndexPath = droppedIndexPath(item: targetItem, childIndex: index) {
            // Check the dragging type.
            if info.draggingPasteboard.availableType(from: [.nodeRowPasteBoardType]) != nil {
                // The user dropped one of your own items.
                handleInternalDrops(outlineView, draggingInfo: info, indexPath: dropIndexPath)
            } else {
                // The user dropped items from the Finder, Photos, Mail, Safari, and so forth.
                handleExternalDrops(outlineView, draggingInfo: info, dropIndexPath: dropIndexPath, childIndex: index)
            }
        }
        return true
    }
    
    /** The system calls this when the dragging session ends. Use this to know when the dragging source
    	operation ends at a specific location, such as the Trash (by checking for an operation of NSDragOperationDelete).
 	*/
    func outlineView(_ outlineView: NSOutlineView,
                     draggingSession session: NSDraggingSession,
                     endedAt screenPoint: NSPoint,
                     operation: NSDragOperation) {
        if operation == .delete,
            let items = session.draggingPasteboard.pasteboardItems {
            var itemsToRemove = [Node]()
            
            // Find the items the user is dragging to the Trash (as a dictionary containing their row numbers).
            for draggedItem in items {
                if let item = itemFromPasteboardItem(draggedItem) {
                    if let itemToRemove = OutlineViewController.node(from: item) {
                        itemsToRemove.append(itemToRemove)
                    }
                }
            }
            removeItems(itemsToRemove)
        }
    }
    
    // MARK: Utilities

    func handleError(_ error: Error) {
        OperationQueue.main.addOperation {
            if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
        }
    }
    
    // A utility functon to return convert an NSPasteboardItem to an NSTreeNode.
    private func itemFromPasteboardItem(_ item: NSPasteboardItem) -> NSTreeNode? {
        // Obtain the property list and find the row number of the dragged node.
        guard let itemPlist = item.propertyList(forType: .nodeRowPasteBoardType) as? [String: Any],
            let rowIndex = itemPlist[NodePasteboardWriter.UserInfoKeys.row] as? Int else { return nil }

        // Ask the outline view for the tree node.
        return outlineView.item(atRow: rowIndex) as? NSTreeNode
    }
    
    // Find the index path to insert the dropped objects.
    private func droppedIndexPath(item targetItem: Any?, childIndex index: Int) -> IndexPath? {
        let dropIndexPath: IndexPath?
        
        if targetItem != nil {
            // Drop-down inside the tree node: fetch the index path to insert the dropped node.
            dropIndexPath = (targetItem! as AnyObject).indexPath!.appending(index)
        } else {
            // Drop at the top root level.
            if index == -1 { // The drop area might be ambiguous (not at a particular location).
                dropIndexPath = IndexPath(index: contents.count) // Drop at the end of the top level.
            } else {
                dropIndexPath = IndexPath(index: index) // Drop at a particular place at the top level.
            }
        }
        return dropIndexPath
    }
    
}

