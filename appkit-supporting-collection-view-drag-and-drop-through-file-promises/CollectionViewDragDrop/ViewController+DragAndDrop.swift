/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Primary view controller collection view delegate to handle drag and drop.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

// MARK: NSCollectionViewDelegate

extension ViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        return true
    }
    
    /** Dragging Source Support - Required for multi-image drag and drop.
        Return a custom object that implements NSPasteboardWriting (or simply use NSPasteboardItem), or nil to prevent dragging for the item.
    */
    func collectionView(_ collectionView: NSCollectionView,
                        pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        /** Here the sample provide a custom NSFilePromise#imageLiteral(resourceName: "_DSC9930.jpeg")#imageLiteral(resourceName: "_DSC9930.jpeg")Provider.
            Here we provide a custom provider, offering the row to the drag object, and its URL.
        */
        var provider: NSFilePromiseProvider?

        guard let photoItem =
            dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
        let photoFileExtension = photoItem.fileURL.pathExtension
        
        if #available(macOS 11.0, *) {
            let typeIdentifier = UTType(filenameExtension: photoFileExtension)
            provider = FilePromiseProvider(fileType: typeIdentifier!.identifier, delegate: self)
        } else {
            let typeIdentifier =
                  UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, photoFileExtension as CFString, nil)
            provider = FilePromiseProvider(fileType: typeIdentifier!.takeRetainedValue() as String, delegate: self)
        }
        
        // Send out the indexPath and photo's url dictionary.
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
            provider!.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: photoItem.fileURL as Any,
                                  FilePromiseProvider.UserInfoKeys.indexPathKey: data]
        } catch {
            fatalError("failed to archive indexPath to pasteboard")
        }
        return provider
    }
    
    /** This function is used by the collection view to determine a valid drop target.
        Based on the mouse position, the collection view will suggest a proposed (section,item) index path and drop operation.
        These values are in/out parameters and can be changed by the delegate to retarget the drop operation.
        The collection view will propose NSCollectionViewDropOn when the dragging location is closer to
        the middle of the item than either of its edges. Otherwise, it will propose NSCollectionViewDropBefore.
        You may override this default behavior by changing proposedDropOperation or proposedDropIndexPath.
        This function must return a value that indicates which dragging operation the data source will perform.
        It must return something other than NSDragOperationNone to accept the drop.
    */
    func collectionView(_ collectionView: NSCollectionView,
                        validateDrop draggingInfo: NSDraggingInfo,
                        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        var dragOperation: NSDragOperation = []

        // We only support dropping items between rows (not on top of a row).
        guard proposedDropOperation.pointee != .on else { return dragOperation }
        
        // The sample only supports dropping items between rows (not on top of a row).

        let pasteboard = draggingInfo.draggingPasteboard
        
        if let draggingSource = draggingInfo.draggingSource as? NSTableView {
            if draggingSource == collectionView {
                // Drag source came from our own table view.
                dragOperation = [.move]
            }
        } else {
            // Drag source came from another app.
            //
            // Search through the array of NSPasteboardItems.
            guard let items = pasteboard.pasteboardItems else { return dragOperation }
            for item in items {
                var type: NSPasteboard.PasteboardType
                if #available(macOS 11.0, *) {
                    type = NSPasteboard.PasteboardType(UTType.image.identifier)
                } else {
                    type = (kUTTypeImage as NSPasteboard.PasteboardType)
                }
                if item.availableType(from: [type]) != nil {
                    // Drag source is coming from another app as a promised image file (for example from Photos app).
                    dragOperation = [.copy]
                }
            }
        }
        
        // Has a drop operation been determined yet?
        if dragOperation == [] {
            // Look for possible URLs you can consume.
            var acceptedTypes: [String]
            if #available(macOS 11.0, *) {
                acceptedTypes = [UTType.image.identifier]
            } else {
                acceptedTypes = [kUTTypeImage as String]
            }
            
            let options = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true,
                           NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: acceptedTypes]
                as [NSPasteboard.ReadingOptionKey: Any]
            // Look only for image urls.
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options), !urls.isEmpty {
                // One or more of the URLs in this drag is image file.
                // The sample allows for this; a user may be able to drag in a mix of files, any one of them being an image file.
                dragOperation = [.copy]
            }
        }
        return dragOperation
    }

    // Find the proper drop location relative to the provided indexPath.
    func dropLocation(indexPath: IndexPath) -> IndexPath {
        var toIndexPath = indexPath
        if indexPath.item == 0 {
            toIndexPath = IndexPath(item: indexPath.item, section: indexPath.section)
        } else {
            toIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)
        }
        return toIndexPath
    }
    
    func dropInternalPhotos(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        var snapshot = self.dataSource.snapshot()

        draggingInfo.enumerateDraggingItems(
            options: NSDraggingItemEnumerationOptions.concurrent,
            for: collectionView,
            classes: [NSPasteboardItem.self],
            searchOptions: [:],
            using: {(draggingItem, idx, stop) in
                if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                    do {
                        if let indexPathData = pasteboardItem.data(forType: .itemDragType), let photoIndexPath =
                            try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(indexPathData) as? IndexPath {
                                if let photoItem = self.dataSource.itemIdentifier(for: photoIndexPath) {
                                    // Find out the proper indexPath drop point.
                                    let toIndexPath = self.dropLocation(indexPath: indexPath)
                                    
                                    let dropItemLocation = snapshot.itemIdentifiers[toIndexPath.item]
                                    if toIndexPath.item == 0 {
                                        // Item is being dropped at the beginning.
                                        snapshot.moveItem(photoItem, beforeItem: dropItemLocation)
                                    } else {
                                        // Item is being dropped between items or at the very end.
                                        snapshot.moveItem(photoItem, afterItem: dropItemLocation)
                                    }
                                }
                            }
                    } catch {
                        Swift.debugPrint("failed to unarchive indexPath for dropped photo item.")
                    }
                }
            })
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    /** Insert the given url as a PhotoItem to the target row number.
        Return false if loading image fails and the URL is not inserted.
    */
    func insertURL(_ url: URL, toIndexPath: IndexPath) -> Bool {
        var urlInserted = false
        do {
            let resourceValues = try url.resourceValues(forKeys: Set([.typeIdentifierKey]))
            var urlTypeConformsToImage = false
            
            if let typeIdentifier = resourceValues.typeIdentifier {
                // The file URL has a type identifier, use it to create it's UTType to check for conformity.
                if #available(macOS 11.0, *) {
                    if let fileUTType = UTType(typeIdentifier) {
                        urlTypeConformsToImage = fileUTType.conforms(to: UTType.image)
                    }
                } else {
                    urlTypeConformsToImage = UTTypeConformsTo(typeIdentifier as CFString, kUTTypeImage)
                }
            } else {
                // The file URL does not have a type identifier, use the extension to determine if it's an image type.
                let urlExtension = url.pathExtension
                if #available(macOS 11.0, *) {
                    if let type = UTType(filenameExtension: urlExtension) {
                        if type.conforms(to: UTType.image) {
                            urlTypeConformsToImage = true
                        }
                    }
                } else {
                    let typeIdentifier =
                        UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, urlExtension as CFString, nil)
                    urlTypeConformsToImage = UTTypeConformsTo(typeIdentifier!.takeRetainedValue() as CFString, kUTTypeImage)
                }
            }
            
            if urlTypeConformsToImage {
                // URL is an image file; add it to the collection view.
                var snapshot = self.dataSource.snapshot()
                
                let photoItem = PhotoItem(url: url)

                // Set up to be notified when the photo's thumbnail is ready.
                photoItem.thumbnailDelegate = self
                
                // Start to load the image.
                photoItem.loadImage()
                
                if snapshot.itemIdentifiers.isEmpty {
                    // No items yet in the snapshot, so just append it.
                    snapshot.appendItems([photoItem])
                } else {
                    let dropItemLocation = snapshot.itemIdentifiers[toIndexPath.item]
                    if toIndexPath.item == 0 {
                        // Item is being dropped at the beginning.
                        snapshot.insertItems([photoItem], beforeItem: dropItemLocation)
                    } else {
                        // Item is being dropped between items or at the very end.
                        snapshot.insertItems([photoItem], afterItem: dropItemLocation)
                    }
                }
                
                self.dataSource.apply(snapshot, animatingDifferences: true)
                urlInserted = true
            }
        } catch {
            Swift.debugPrint("Can't obtain the type identifier for \(url): \(error)")
        }
        return urlInserted
    }
    
    /** Given an NSDraggingInfo from an incoming drag, handle any and all promise drags.
        Note that promise drags can come from any app that offers it (i.e. Safari or Photos).
    */
    func handlePromisedDrops(draggingInfo: NSDraggingInfo, toIndexPath: IndexPath) -> Bool {
        var handled = false
        if let promises = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) {
            if !promises.isEmpty {
                // We have incoming drag items that are file promises.
                for promise in promises {
                    if let promiseReceiver = promise as? NSFilePromiseReceiver {
                        // Show the progress indicator as we start receiving this promised file.
                        progressIndicator.isHidden = false
                        progressIndicator.startAnimation(self)
                        
                        // Ask your file promise receiver to fulfill on their promise.
                        promiseReceiver.receivePromisedFiles(atDestination: destinationURL, options: [:],
                                                             operationQueue: self.filePromiseQueue) { (fileURL, error) in
                            /** Finished copying the promised file.
                                Back on the main thread, insert the newly created image file into the table view.
                            */
                            OperationQueue.main.addOperation {
                                if error != nil {
                                    self.reportURLError(fileURL, error: error!)
                                } else {
                                    _ = self.insertURL(fileURL, toIndexPath: toIndexPath)
                                }
                                // Stop the progress indicator as you are done receiving this promised file.
                                self.progressIndicator.isHidden = true
                                self.progressIndicator.stopAnimation(self)
                            }
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
    
    func dropExternalPhotos(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        // Find the proper indexPath drop point for the external photos.
        let toIndexPath = dropLocation(indexPath: indexPath)

        // If possible, first handle the incoming dragged photos as file promises.
        if handlePromisedDrops(draggingInfo: draggingInfo, toIndexPath: toIndexPath) {
            // Successfully processed the dragged items that were promised.
        } else {
            // Incoming drag was not propmised, so move in all the outside dragged items as URLs.
            var foundNonImageFiles = false
            
            // Move in all the outside dragged items as URLs.
            draggingInfo.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: collectionView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                        // Are we being passed a file URL as the drag type?
                        let itemType = pasteboardItem.availableType(from: [.fileURL]),
                        let filePath = pasteboardItem.string(forType: itemType),
                        let url = URL(string: filePath) {
                            if !self.insertURL(url, toIndexPath: toIndexPath) {
                                foundNonImageFiles = true
                            }
                    }
                })
            
            // If any of the dragged URLs were not image files, alert the user.
            if foundNonImageFiles {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("CannotImportTitle", comment: "")
                alert.informativeText = NSLocalizedString("CannotImportMessage", comment: "")
                alert.addButton(withTitle: NSLocalizedString("OKTitle", comment: ""))
                alert.alertStyle = .warning
                alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            }
        }
    }

    /** This function is called when the mouse is released over a collection view that previously decided to
        allow a drop via the above validateDrop function. At this time, the delegate should incorporate the data from the
        dragging pasteboard and update the collection view's contents. You must implement this function for your
        collection view to be a drag destination.
    */
    func collectionView(_ collectionView: NSCollectionView,
                        acceptDrop draggingInfo: NSDraggingInfo,
                        indexPath: IndexPath,
                        dropOperation: NSCollectionView.DropOperation) -> Bool {
        // Check where the dragged items are coming from.
        if let draggingSource = draggingInfo.draggingSource as? NSCollectionView, draggingSource == collectionView {
            // Drag source from your own collection view.
            // Move each dragged photo item to their new place.
            dropInternalPhotos(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        } else {
            // The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
            // Drop each dragged image file to their new place.
            dropExternalPhotos(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        return true
    }
    
    /** Dragging Source Support - Optional. Implement this function to know when the dragging session has ended.
        This delegate function can be used to know when the dragging source operation ended at a specific location,
        such as the trash (by checking for an operation of NSDragOperationDelete).
    */
    func collectionView(_ collectionView: NSCollectionView,
                        draggingSession session: NSDraggingSession,
                        endedAt screenPoint: NSPoint,
                        dragOperation operation: NSDragOperation) {
        if operation == .delete, let items = session.draggingPasteboard.pasteboardItems {
            // User dragged the photo to the Finder's trash.
            for pasteboardItem in items {
                if let photoIdx = pasteboardItem.propertyList(forType: .itemDragType) as? Int {
                    // User dragged the photo at index 'photoIdx' to the Trash.
                    let indexPath = IndexPath(item: photoIdx, section: 0)
                    let photo = self.dataSource.itemIdentifier(for: indexPath)
                    Swift.debugPrint("Remove \(photo!.title)")
                }
            }
        }
    }
    
    // Reports the error and related URL, generated from the NSFilePromiseReceiver operation.
    func reportURLError(_ url: URL, error: Error) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("ErrorTitle", comment: "")
        alert.informativeText = String(format: NSLocalizedString("ErrorMessage", comment: ""), url.lastPathComponent, error.localizedDescription)
        alert.addButton(withTitle: NSLocalizedString("OKTitle", comment: ""))
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }

}

// MARK: - NSFilePromiseProviderDelegate

extension ViewController: NSFilePromiseProviderDelegate {
    
    /** This function is called at drop time to provide the title of the file being dropped.
        This sample uses a hard-coded string for simplicity, but depending on your use case, you should take the fileType parameter into account.
    */
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        // Return the photoItem's URL file name.
        let photoItem = photoFromFilePromiserProvider(filePromiseProvider: filePromiseProvider)
        return (photoItem?.fileURL.lastPathComponent)!
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        do {
            if let photoItem = photoFromFilePromiserProvider(filePromiseProvider: filePromiseProvider) {
                /** Copy the file to the location provided to you. You always do a copy, not a move.
                    It's important you call the completion handler.
                */
                try FileManager.default.copyItem(at: photoItem.fileURL, to: url)
            }
            completionHandler(nil)
        } catch let error {
            OperationQueue.main.addOperation {
                self.presentError(error, modalFor: self.view.window!,
                                  delegate: nil, didPresent: nil, contextInfo: nil)
            }
            completionHandler(error)
        }
    }
    
    /** You should provide a non main operation queue (e.g. one you create) via this function.
        This way you don't stall the main thread while writing the promise file.
    */
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return filePromiseQueue
    }
    
    // Utility function to return a PhotoItem object from the NSFilePromiseProvider.
    func photoFromFilePromiserProvider(filePromiseProvider: NSFilePromiseProvider) -> PhotoItem? {
        var returnPhoto: PhotoItem?
        if let userInfo = filePromiseProvider.userInfo as? [String: AnyObject] {
            do {
                if let indexPathData = userInfo[FilePromiseProvider.UserInfoKeys.indexPathKey] as? Data {
                    if let indexPath =
                        try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(indexPathData) as? IndexPath {
                            returnPhoto = dataSource.itemIdentifier(for: indexPath)
                        }
                }
            } catch {
                fatalError("failed to unarchive indexPath from promise provider.")
            }
        }
        return returnPhoto
    }
    
}
