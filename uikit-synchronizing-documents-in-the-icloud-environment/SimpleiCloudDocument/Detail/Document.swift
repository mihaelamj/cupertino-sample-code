/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The document class that implements UIDocument's reading and writing methods, and manages document changes.
*/

import UIKit

class Document: UIDocument {
    static let extensionName = "sicd" // Document extension name.
    private let descriptionFileName = "Description.plist"
    
    // Tracking the differences between the document and the view.
    // New images are of [URL] type because they can be outside of the document bundle.
    // unpresentedPeerChanges: changes that persist, but don’t appear in the UI.
    // unsavedUserChanges: changes that are visible in the UI, but the app doesn't save.
    //
    struct Changes {
        var newImageURLs = [URL]()
        var deletedImageNames = [String]()
        var updatedImageNames = [String]()
        
        var isEmpty: Bool {
            return newImageURLs.isEmpty && deletedImageNames.isEmpty && updatedImageNames.isEmpty
        }
        mutating func clear() {
            newImageURLs.removeAll()
            deletedImageNames.removeAll()
            updatedImageNames.removeAll()
        }
    }
    
    // A dispatch queue to serialize the access to the properties from multiple threads.
    //
    private lazy var accessQueue: DispatchQueue = {
        return DispatchQueue(label: "Document", attributes: .concurrent)
    }()
    
    // Don't access these properties directly.
    //
    private var _fileWrappersUnderRoot: [String: FileWrapper]?
    private var _unsavedUserChanges = Changes()

    // This sample only accesses unpresentedPeerChanges from the main queue.
    //
    private(set) var unpresentedPeerChanges = Changes()
}

// MARK: - UIDocument overridable
//
extension Document {
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        print("\(#function)")
        // content must be a FileWrapper, and documentWrapper.fileWrappers must have at least
        // description.plist.
        //
        guard let documentWrapper = contents as? FileWrapper,
              let imageWrappers = documentWrapper.fileWrappers else {
            fatalError("contents isn't a valid file wrapper. The document may be corrupted.")
        }
        
        // Clear unpresented peer changes, if necessary, then gather the unpresented peer changes by
        // comparing the file modification date, and copy the document file wrappers.
        //
        if !unpresentedPeerChanges.isEmpty {
            print("? Loading document before unpresentedPeerChanges is empty!")
            unpresentedPeerChanges.clear()
        }
        unpresentedPeerChanges = gatherPeerChanges(with: imageWrappers)
        fileWrappersUnderRoot = documentWrapper.fileWrappers
    }
    
    // Provide content for a new document. Return a FileWrapper to create a document
    // package with a description file.
    // The override of save(to:for:completionHandler:) uses super's implementation
    // for .forCreating, which still calls this method for content.
    // Having a description file for a document package makes sense for a real-world app.
    // This sample doesn't maintain the file though because that isn't the focus.
    //
    override func contents(forType typeName: String) throws -> Any {
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
        let version = "<key>Version</key><string>1</string>".data(using: .utf8)
        let content = version ?? Data()
        fileWrapper.addRegularFile(withContents: content, preferredFilename: descriptionFileName)
        return fileWrapper
    }
    
    override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        if saveOperation != .forCreating {
            print("\(#function)")
            return performAsynchronousFileAccess {
                let fileCoordinator = NSFileCoordinator(filePresenter: self)
                fileCoordinator.coordinate(writingItemAt: self.fileURL, options: .forMerging, error: nil) { newURL in
                    let success = self.fulfillUnsavedChanges()
                    self.fileModificationDate = Date()
                    if let completionHandler = completionHandler {
                        DispatchQueue.main.async {
                            completionHandler(success)
                        }
                    }
                }
            }
        }
        super.save(to: url, for: saveOperation, completionHandler: completionHandler)
    }

    // UIDocument calls this method to revert the document to the most recent document data
    // on-disk after synchronizing peer changes.
    // Print this call to reveal the process.
    //
    override func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
        print("\(#function)")
        super.revert(toContentsOf: url, completionHandler: completionHandler)
    }
    
    // To accommodate the deletion, close the document, if necessary, then call super's implementation.
    //
    override func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        guard !documentState.contains(.closed) else {
            super.accommodatePresentedItemDeletion(completionHandler: completionHandler)
            return
        }
        close { success in
            if !success {
                print("Failed to close the document: \(self.fileURL)")
            }
            super.accommodatePresentedItemDeletion(completionHandler: completionHandler)
        }
    }
    
    // Override to reveal the document reading or writing error, if any.
    //
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        print("\(#function): \(error)")
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}

// MARK: - Private methods run in callbacks of asynchronously coordinated file access.
//
extension Document {
    private func fulfillUnsavedChanges() -> Bool {
        // Remove the deleted image files if they exist.
        //
        let fileManager = FileManager.default
        var success = true
        
        for imageName in unsavedDeletedImageNames {
            let imageFileURL = fileURL.appendingPathComponent(imageName)
            guard fileManager.fileExists(atPath: imageFileURL.path) else { continue }
            do {
                try fileManager.removeItem(at: imageFileURL)
            } catch {
                print("Failed to delete an image file: \(error)")
                success = false
            }
        }
        // Copy the cached image into the document bundle.
        // Use the image names from Photo Library because they're unique.
        //
        for imageURL in unsavedNewImageURLs {
            let targetURL = fileURL.appendingPathComponent(imageURL.lastPathComponent)
            do {
                try fileManager.copyItem(at: imageURL, to: targetURL)
            } catch {
                print("Failed to copy an image file: \(error)")
                success = false
            }
            
        }
        // Update fileWrappersUnderRoot by creating a new one without loading the image data,
        // then clear the new and deleted items.
        //
        let documentWrapper = try? FileWrapper(url: fileURL)
        fileWrappersUnderRoot = documentWrapper?.fileWrappers
        clearUnsavedUserChanges()
        return success
    }
    
    private func gatherPeerChanges(with imageWrappers: [String: FileWrapper]) -> Changes {
        var changes = Changes()
        
        // All images are new if the document doesn't have any file wrappers.
        //
        guard let originalImageWrappers = fileWrappersUnderRoot, !originalImageWrappers.isEmpty else {
            changes.newImageURLs = Array(imageWrappers.keys).map { URL(string: $0)! }
            return changes
        }

        // If imageWrappers is empty, put all the keys of the original image wrappers to deletedImageNames.
        //
        changes.deletedImageNames = Array(originalImageWrappers.keys)
        guard !imageWrappers.isEmpty else {
            return changes
        }

        // Check the modificationDate for updated images.
        // If the date doesn't change, the content doesn't change, so there is no need to update the UI.
        // If an image doesn't exist in originalImageWrappers, gather it as a new one.
        // Remove the names of the existing images so deletedImageNames contains the right names.
        //
        for (name, newImageWrapper) in imageWrappers {
            guard let oldImageWrapper = originalImageWrappers[name] else {
                changes.newImageURLs.append(URL(string: name)!)
                continue
            }
            let key = FileAttributeKey.modificationDate.rawValue
            if let newDate = newImageWrapper.fileAttributes[key] as? Date,
               let oldDate = oldImageWrapper.fileAttributes[key] as? Date, newDate > oldDate {
                changes.updatedImageNames.append(name)
            }
            if let index = changes.deletedImageNames.firstIndex(where: { $0 == name }) {
                changes.deletedImageNames.remove(at: index)
            }
        }
        return changes
    }
}

// MARK: - Asynchronously retrieve images and image items.
// Note that the completion handler runs in a secondary queue.
// Clients should dispatch their code appropriately.
//
extension Document {
    // Retrieve the image for the specified image name.
    // If the image file doesn't exist yet, coordinated reading still succeeds,
    // but Data(contentsOf: newURL) returns nil.
    //
    func retrieveImageAsynchronously(with imageName: String, completionHandler: @escaping (UIImage?) -> Void) {
        performAsynchronousFileAccess {
            let imageFileURL = self.fileURL.appendingPathComponent(imageName)
            let fileCoordinator = NSFileCoordinator(filePresenter: self)
            fileCoordinator.coordinate(readingItemAt: imageFileURL, options: .withoutChanges, error: nil) { newURL in
                if let imageData = try? Data(contentsOf: newURL), let image = UIImage(data: imageData) {
                    completionHandler(image)
                } else {
                    completionHandler(nil)
                }
            }
        }
    }

    // This is a public method for generating thumbnails for the specified image names.
    // Instead of generating thumbnails and keeping the image data in the UIDocument loading method,
    // this method doesn't keep the image data, so it better controls the memory footprint.
    //
    func createImageItemsAsynchronously(with imageNames: [String]? = nil,
                                        completionHandler: @escaping ([ImageItem]?) -> Void) {
        performAsynchronousFileAccess {
            let fileCoordinator = NSFileCoordinator(filePresenter: self)
            fileCoordinator.coordinate(readingItemAt: self.fileURL, options: .withoutChanges, error: nil) { newURL in
                let items = self.imageItems(with: imageNames)
                completionHandler(items)
            }
        }
    }
    
    // Retrieve the image items with the image names.
    // If the imageNames argument is nil, return all image items in the document.
    //
    private func imageItems(with imageNames: [String]? = nil) -> [ImageItem]? {
        guard let imageWrappers = fileWrappersUnderRoot else { return nil }

        var items = [ImageItem]()
        let names = imageNames ?? Array(imageWrappers.keys)
        
        for imageName in names where imageName != descriptionFileName {
            let imageFileURL = self.fileURL.appendingPathComponent(imageName)
            guard let imageData = try? Data(contentsOf: imageFileURL) else {
                continue
            }
            let image = imageData.thumbnail()
            items.append(ImageItem(name: imageName, thumbnail: image))
        }
        return items.isEmpty ? nil : items
    }
}

// MARK: - Accessors
// Serialize the access with a queue to avoid potential thread violations.
//
extension Document {
    private func performWriterBlock(_ writerBlock: @escaping () -> Void) {
        accessQueue.async(flags: .barrier) {
            writerBlock()
        }
    }
    
    private func performReaderBlockAndWait<T>(_ readerBlock: () -> T) -> T {
        return accessQueue.sync {
            return readerBlock()
        }
    }
    
    private var fileWrappersUnderRoot: [String: FileWrapper]? {
        get {
            return performReaderBlockAndWait {
                return self._fileWrappersUnderRoot
            }
        }
        set {
            performWriterBlock {
                self._fileWrappersUnderRoot = newValue
            }
        }
    }
    
    private var unsavedDeletedImageNames: [String] {
        return performReaderBlockAndWait {
            self._unsavedUserChanges.deletedImageNames
        }
    }
    
    func addUnsavedDeletedImageName(_ imageName: String) {
        performWriterBlock {
            self._unsavedUserChanges.deletedImageNames.append(imageName)
        }
    }
    
    var unsavedNewImageURLs: [URL] {
        return performReaderBlockAndWait {
            self._unsavedUserChanges.newImageURLs
        }
    }
    
    func removeUnsavedNewImageURL(at index: Int) {
        performWriterBlock {
            self._unsavedUserChanges.newImageURLs.remove(at: index)
        }
    }
    
    func addUnsavedNewImageURL(_ imageURL: URL) {
        performWriterBlock {
            self._unsavedUserChanges.newImageURLs.append(imageURL)
        }
    }
    
    private func clearUnsavedUserChanges() {
        performWriterBlock {
            self._unsavedUserChanges.clear()
        }
    }
    
    // Call this only from the main queue because unpresentedPeerChanges isn't protected.
    //
    func clearUnpresentedPeerChanges() {
        unpresentedPeerChanges.clear()
    }
}
