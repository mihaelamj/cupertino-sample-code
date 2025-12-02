/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Primary view controller table view data source for handling drag and drop.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

// MARK: NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    // A PhotoItem in our table is being dragged for this given row, provide the pasteboard writer for this item.
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        /** Return a custom NSFilePromiseProvider.
            Here we provide a custom provider, offering the row to the drag object, and it's URL.
        */
        var provider: FilePromiseProvider
        
        let photoItem = contentArray[row]
        let photoFileExtension = photoItem.fileURL.pathExtension

        if #available(macOS 11.0, *) {
            let typeIdentifier = UTType(filenameExtension: photoFileExtension)
            provider = FilePromiseProvider(fileType: typeIdentifier!.identifier, delegate: self)
        } else {
            let typeIdentifier =
                  UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, photoFileExtension as CFString, nil)
            provider = FilePromiseProvider(fileType: typeIdentifier!.takeRetainedValue() as String, delegate: self)
        }

        // Send over the row number and photo's url dictionary.
        provider.userInfo = [FilePromiseProvider.UserInfoKeys.rowNumberKey: row,
                             FilePromiseProvider.UserInfoKeys.urlKey: photoItem.fileURL as Any]
        return provider
    }
    
    func dragSourceIsFromOurTable(draggingInfo: NSDraggingInfo) -> Bool {
        if let draggingSource = draggingInfo.draggingSource as? NSTableView, draggingSource == tableView {
            return true
        } else {
            return false
        }
    }
        
    // This function is called when a drag is moved over the table view and before it has been dropped.
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        var dragOperation: NSDragOperation = []
        
        // We only support dropping items between rows (not on top of a row).
        guard dropOperation != .on else { return dragOperation }

        if dragSourceIsFromOurTable(draggingInfo: info) {
            // Drag source came from our own table view.
            dragOperation = [.move]
        } else {
            // Drag source came from another app.
            //
            // Search through the array of NSPasteboardItems.
            let pasteboard = info.draggingPasteboard
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
            // Look for possible URLs we can consume.
            var acceptedTypes: [String]
            if #available(macOS 11.0, *) {
                acceptedTypes = [UTType.image.identifier]
            } else {
                acceptedTypes = [kUTTypeImage as String]
            }

            let options = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true,
                           NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: acceptedTypes]
                as [NSPasteboard.ReadingOptionKey: Any]
            let pasteboard = info.draggingPasteboard
            // Look only for image urls.
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) {
                if !urls.isEmpty {
                    /** One or more of the URLs in this drag is image file.
                        We allow for this; a user may be able to drag in a mix of files, any one of them being an image file.
                    */
                    dragOperation = [.copy]
                }
            }
        }

        return dragOperation
    }
    
    // Drop the internal dragged photos in this table view to the target row number.
    func dropInternalPhotos(_ tableView: NSTableView, draggingInfo: NSDraggingInfo, toRow: Int) {
        var indexesToMove = IndexSet()
        
        draggingInfo.enumerateDraggingItems(
            options: NSDraggingItemEnumerationOptions.concurrent,
            for: tableView,
            classes: [NSPasteboardItem.self],
            searchOptions: [:],
            using: {(draggingItem, idx, stop) in
                if  let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                    let photoRow = pasteboardItem.propertyList(forType: .rowDragType) as? Int {
                        indexesToMove.insert(photoRow)
                    }
            })
                
        // Move/drop the photos in their correct place using their indexes.
        moveObjectsFromIndexes(indexesToMove, toIndex: toRow)
        
        // Set the selected rows to those that were just moved.
        let rowsMovedDown = rowsMovedDownward(toRow, indexSet: indexesToMove)
        let selectionRange = toRow - rowsMovedDown..<toRow - rowsMovedDown + indexesToMove.count
        let indexSet = IndexSet(integersIn: selectionRange)
        tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
    
    /** Insert the given url as a PhotoItem to the target row number.
        Return false if loading image fails and the URL and is not inserted.
    */
    func insertURL(_ url: URL, toRow: Int) -> Bool {
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
                    if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeImage) {
                        urlTypeConformsToImage = true
                    }
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
                    if UTTypeConformsTo(typeIdentifier!.takeRetainedValue() as CFString, kUTTypeImage) {
                        urlTypeConformsToImage = true
                    }
                }
            }
            
            if urlTypeConformsToImage {
                // URL is an image file, add it to the table view.
                let photoItem = PhotoItem(url: url)
                
                // Set up ourselves to be notified when the photo's thumbnail is ready.
                photoItem.thumbnailDelegate = self
                
                // Start to load the image.
                photoItem.loadImage()
                
                self.contentArray.insert(photoItem, at: toRow)
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
    func handlePromisedDrops(draggingInfo: NSDraggingInfo, toRow: Int) -> Bool {
        var handled = false
        if let promises = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) {
            if !promises.isEmpty {
                // We have incoming drag item(s) that are file promises.

                // At the start of insertion(s), clear the current table view selection.
                tableView.deselectAll(self)
                
                for promise in promises {
                    if let promiseReceiver = promise as? NSFilePromiseReceiver {
                        // Show the progress indicator as we start receiving this promised file.
                        progressIndicator.isHidden = false
                        progressIndicator.startAnimation(self)
                        
                        // Ask our file promise receiver to fulfull on their promise.
                        promiseReceiver.receivePromisedFiles(atDestination: destinationURL,
                                                             options: [:],
                                                             operationQueue: filePromiseQueue) { (fileURL, error) in
                            /** Finished copying the promised file.
                                Back on the main thread, insert the newly created image file into the table view.
                            */
                            OperationQueue.main.addOperation {
                                if error != nil {
                                    self.reportURLError(fileURL, error: error!)
                                } else {
                                    _ = self.insertURL(fileURL, toRow: toRow)

                                    /** Select the newly inserted photo,
                                        extend the selection so to accumulate multiple selected photos.
                                    */
                                    let indexSet = IndexSet(integer: toRow)
                                    self.tableView.selectRowIndexes(indexSet, byExtendingSelection: true)
                                }
                                // Stop the progress indicator as we are done receiving this promised file.
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
    
    // Drop the internal dragged photos in this table view to the target row.
    func dropExternalPhotos(_ tableView: NSTableView, draggingInfo: NSDraggingInfo, toRow: Int) {
        // If possible, first handle the incoming dragged photos as file promises.
        if handlePromisedDrops(draggingInfo: draggingInfo, toRow: toRow) {
            // Successfully processed the dragged items that were promised to us.
        } else {
            // Incoming drag was not propmised, so move in all the outside dragged items as URLs.
            var foundNonImageFiles = false
            var numItemsInserted = 0
            draggingInfo.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: tableView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                        // Are we being passed a file URL as the drag type?
                        if  let itemType = pasteboardItem.availableType(from: [.fileURL]),
                            let filePath = pasteboardItem.string(forType: itemType),
                            let url = URL(string: filePath) {
                                if self.insertURL(url, toRow: toRow) {
                                    numItemsInserted += 1
                                } else {
                                    foundNonImageFiles = true
                            }
                        }
                    }
                })
            
            // Select the newly inserted photo items.
            let selectionRange = toRow..<toRow + numItemsInserted
            let indexSet = IndexSet(integersIn: selectionRange)
            tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
            
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
    
    // The mouse was released over a table view that previously decided to allow a drop.
    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        // Check where the dragged items are coming.
        if dragSourceIsFromOurTable(draggingInfo: info) {
            /** Drag source came from our own table view.
                Move each dragged photo item to their new place.
            */
            dropInternalPhotos(tableView, draggingInfo: info, toRow: row)
        } else {
            /** The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
                Drop each dragged image file to their new place.
            */
            dropExternalPhotos(tableView, draggingInfo: info, toRow: row)
        }
        return true
    }
    
    /** Implement this function to know when the dragging session has ended.
        This delegate function can be used to know when the dragging source operation ended at a specific location,
        such as the trash (by checking for an operation of NSDragOperationDelete).
    */
    func tableView(_ tableView: NSTableView,
                   draggingSession session: NSDraggingSession,
                   endedAt screenPoint: NSPoint,
                   operation: NSDragOperation) {
        if operation == .delete, let items = session.draggingPasteboard.pasteboardItems {
            // User dragged the photo to the Finder's trash.
            for pasteboardItem in items {
                if let photoRow = pasteboardItem.propertyList(forType: .rowDragType) as? Int {
                    let photo = contentArray[photoRow]
                    Swift.debugPrint("Remove \(photo.title)")
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
    
    // MARK: - Table Row Movement Utilities

    // Move the set of objects within the indexSet to the 'toIndex' row number.
    func moveObjectsFromIndexes(_ indexSet: IndexSet, toIndex: Int) {
        var insertIndex = toIndex
        var currentIndex = indexSet.last
        var aboveInsertCount = 0
        var removeIndex = 0
      
        while currentIndex != nil {
            if currentIndex! >= toIndex {
                removeIndex = currentIndex! + aboveInsertCount
                aboveInsertCount += 1
            } else {
                removeIndex = currentIndex!
                insertIndex -= 1
            }
          
            let object = contentArray[removeIndex]
            contentArray.remove(at: removeIndex)
            contentArray.insert(object, at: insertIndex)
          
            currentIndex = indexSet.integerLessThan(currentIndex!)
        }
    }
    
    // Returns the number of rows dragged in a downward direction within the table view.
    func rowsMovedDownward(_ row: Int, indexSet: IndexSet) -> Int {
        var rowsMovedDownward = 0
        var currentIndex = indexSet.first
        while currentIndex != nil {
            if currentIndex! < row {
                rowsMovedDownward += 1
            }
            currentIndex = indexSet.integerGreaterThan(currentIndex!)
        }
        return rowsMovedDownward
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
                /** Copy the file to the location provided to us. We always do a copy, not a move.
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
        if  let userInfo = filePromiseProvider.userInfo as? [String: Any],
            let row = userInfo[FilePromiseProvider.UserInfoKeys.rowNumberKey] as? Int {
                returnPhoto = contentArray[row]
        }
        return returnPhoto
    }
    
}
