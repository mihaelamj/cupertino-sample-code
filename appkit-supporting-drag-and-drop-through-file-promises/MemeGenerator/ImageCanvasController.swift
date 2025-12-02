/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the main app image canvas controller for the meme generator.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

class ImageCanvasController: NSViewController, NSFilePromiseProviderDelegate, ImageCanvasDelegate, NSToolbarDelegate {
   
    enum RuntimeError: Error {
        case unavailableSnapshot
    }

    /// main view
    @IBOutlet weak var imageCanvas: ImageCanvas!
    
    /// Placeholder label which is displayed before any image has been dropped onto the app.
    @IBOutlet weak var placeholderLabel: NSTextField!
    
    /// Image label which can be placed in a custom toolbar item.
    @IBOutlet weak var imageLabel: NSTextField!

    /// Queue used for reading and writing file promises.
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    /// Directory URL used for accepting file promises.
    private lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
    /// Updates the canvas with a given image.
    private func handleImage(_ image: NSImage?) {
        imageCanvas.image = image
        placeholderLabel.isHidden = (image != nil)
        imageLabel.stringValue = imageCanvas.imageDescription
    }

    /// Updates the canvas with a given image file.
    private func handleFile(at url: URL) {
        let image = NSImage(contentsOf: url)
        OperationQueue.main.addOperation {
            self.handleImage(image)
            if let windowController = self.view.window!.windowController as? WindowController {
                windowController.addTextToolbarItem.isEnabled = true
            }
        }
    }
    
    /// Displays an error.
    private func handleError(_ error: Error) {
        OperationQueue.main.addOperation {
            if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
            self.imageCanvas.isLoading = false
        }
    }
    
    /// Displays a progress indicator.
    private func prepareForUpdate() {
        imageCanvas.isLoading = true
        placeholderLabel.isHidden = true
    }

    // MARK: - NSViewController

    /// - Tag: RegisterPromiseReceiver
    override func viewDidLoad() {
        super.viewDidLoad()
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        
        imageLabel.stringValue = ""
    }
    
    // MARK: - Actions
    
    @IBAction func addText(_ sender: AnyObject) {
        imageCanvas.addTextField()
    }
    
    // MARK: - ImageCanvasDelegate

    func draggingEntered(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    func performDragOperation(forImageCanvas imageCanvas: ImageCanvas, sender: NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]

        // Look for possible URLs we can consume (image URLs).
        var acceptedTypes: [String]
        if #available(macOS 11.0, *) {
            acceptedTypes = [UTType.image.identifier]
        } else {
            acceptedTypes = [kUTTypeImage as String]
        }
        
        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: acceptedTypes
        ]
        /// - Tag: HandleFilePromises
        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { (draggingItem, _, _) in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                self.prepareForUpdate()
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, options: [:],
                                                         operationQueue: self.workQueue) { (fileURL, error) in
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.handleFile(at: fileURL)
                    }
                }
            case let fileURL as URL:
                self.handleFile(at: fileURL)
            default: break
            }
        }
        
        return true
    }
    
    func pasteboardWriter(forImageCanvas imageCanvas: ImageCanvas) -> NSPasteboardWriting {
        var fileType = ""
        if #available(macOS 11.0, *) {
            fileType = UTType.jpeg.identifier
        } else {
            fileType = kUTTypeJPEG as String
        }
        let provider = NSFilePromiseProvider(fileType: fileType, delegate: self)
        provider.userInfo = imageCanvas.snapshotItem
        return provider
    }
    
    // MARK: - NSFilePromiseProviderDelegate
    
    /// - Tag: ProvideFileName
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        let droppedFileName = NSLocalizedString("DropFileTitle", comment: "")
        return droppedFileName + ".jpg"
    }
    
    /// - Tag: ProvideOperationQueue
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }
    
    /// - Tag: PerformFileWriting
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            if let snapshot = filePromiseProvider.userInfo as? ImageCanvas.SnapshotItem {
                try snapshot.jpegRepresentation?.write(to: url)
            } else {
                throw RuntimeError.unavailableSnapshot
            }
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }
    }
}
