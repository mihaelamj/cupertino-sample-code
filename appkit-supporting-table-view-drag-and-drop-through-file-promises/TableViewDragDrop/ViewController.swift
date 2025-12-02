/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller for this sample.
*/

import Cocoa

extension NSPasteboard.PasteboardType {
    static let rowDragType = NSPasteboard.PasteboardType("com.mycompany.mydragdrop")
}

class ViewController: NSViewController {
   
	@IBOutlet weak var tableView: NSTableView!
    
    /** This contentArray need @objc to make it key value compliant with this view controller,
        and so they are accessible and usable with Cocoa bindings.
    */
    @objc dynamic var contentArray = [PhotoItem]()
    
    var progressIndicator: NSProgressIndicator!
    
    // Queue used for initially loading all the photos.
    var loaderQueue = OperationQueue()
    
    // Queue used for reading and writing file promises.
    var filePromiseQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()
    
    // The temporary directory URL used for accepting file promises.
    lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
	// MARK: - View life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        setupProgressIndicator()
        
        tableView.dataSource = self // Necessary for drag and drop.
        
        // Accept file promises from apps like Safari.
        tableView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        tableView.registerForDraggedTypes([
            .fileURL, // Accept dragging of image file URLs from other apps.
            .rowDragType]) // Intra drag of row items numbers within the table.

        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)
        
        // Set up the async operation to load all the photos from the Pictures folder.
        let loadPhotosOperation = LoadPhotosOperation()
        
        // Set up the completion block so we know that all the photos are loaded.
        loadPhotosOperation.completionBlock = {
            // Finished loading all the image files.
            OperationQueue.main.addOperation {
                if loadPhotosOperation.loadedImages.isEmpty {
                    Swift.debugPrint("No images found in the Pictures folder.")
                } else {
                    // Assign our new content from the photos loader.
                    self.contentArray = loadPhotosOperation.loadedImages

                    for photo in self.contentArray {
                        // Set up ourselves to be notified when this photo's thumbnail image is ready.
                        photo.thumbnailDelegate = self
                    }

                    self.tableView.reloadData()
                }
            }
        }
        // Start the async load all the photos.
        loaderQueue.addOperation(loadPhotosOperation)
	}
    
    func setupProgressIndicator() {
        // Create the progress indicator for asyncronous copies of promised files.
        progressIndicator = NSProgressIndicator(frame: NSRect())
        progressIndicator.controlSize = .regular
        progressIndicator.sizeToFit()
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)
        // Center it to this view controller.
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc
    func inspect() {
        // Handle user double-click on the table row.
        let theRow = tableView.selectedRow
        if theRow != -1 {
            let photoItem = contentArray[theRow]
            NSWorkspace.shared.open(photoItem.fileURL)
        }
    }
 
}

// MARK: - ThumbnailDelegate

extension ViewController: ThumbnailDelegate {
    
    func thumbnailDidFinish(_ photoItem: PhotoItem) {
        // Finished with generating thumbnail for this photo.
        
        // Find the row to update the thumbnail.
        if let photoTableRow = contentArray.firstIndex(of: photoItem) {
            // Update the table row.
            tableView.reloadData(forRowIndexes: IndexSet(integer: photoTableRow), columnIndexes: IndexSet(integer: 0))
        }
    }
    
}
