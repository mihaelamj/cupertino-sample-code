/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of DetailViewController that manages the document state changes.
*/

import Foundation

extension DetailViewController {
    @objc
    func documentStateChanged(_ notification: Notification) {
        guard let document = document else { return }
        printDocumentState(for: document)
        
        // The document state is normal.
        // Update the UI with unpresented peer changes, if any.
        //
        if document.documentState == .normal {
            navigationItem.rightBarButtonItem?.isEnabled = true
            handleConflictsItem.isEnabled = false
            if !document.unpresentedPeerChanges.isEmpty {
                let changes = document.unpresentedPeerChanges
                document.clearUnpresentedPeerChanges()
                updateCollectionView(with: changes)
            }
            return
        }
        // The document has conflicts but no error.
        // Update the UI with unpresented peer changes if any.
        //
        if document.documentState == .inConflict {
            navigationItem.rightBarButtonItem?.isEnabled = true
            handleConflictsItem.isEnabled = true
            if !document.unpresentedPeerChanges.isEmpty {
                let changes = document.unpresentedPeerChanges
                document.clearUnpresentedPeerChanges()
                updateCollectionView(with: changes)
            }
            return
        }
        // The document is in a closed state with no error. Clear the UI.
        //
        if document.documentState == .closed {
            navigationItem.rightBarButtonItem?.isEnabled = false
            handleConflictsItem.isEnabled = false
            title = ""
            var snapshot = DiffableImageSourceSnapshot()
            snapshot.appendSections([0])
            diffableImageSource.apply(snapshot)
            return
        }
        // The document has conflicts. Enable the toolbar item.
        //
        if document.documentState.contains(.inConflict) {
            handleConflictsItem.isEnabled = true
        }
        // The document is editingDisabled. Disable the UI for editing.
        //
        if document.documentState.contains(.editingDisabled) {
            navigationItem.rightBarButtonItem?.isEnabled = false
            handleConflictsItem.isEnabled = false
        }
    }
    
    private func updateCollectionView(with changes: Document.Changes) {
        guard let document = document else { return }
        
        if !changes.deletedImageNames.isEmpty {
            let deletedItems = changes.deletedImageNames.map { ImageItem(name: $0, thumbnail: nil) }
            var snapshot = self.diffableImageSource.snapshot()
            snapshot.deleteItems(deletedItems)
            self.diffableImageSource.apply(snapshot)
        }
        if !changes.updatedImageNames.isEmpty {
            document.createImageItemsAsynchronously(with: changes.updatedImageNames) { updatedItems in
                guard let updatedItems = updatedItems else { return }
                DispatchQueue.main.async {
                    var snapshot = self.diffableImageSource.snapshot()
                    snapshot.reloadItems(updatedItems)
                    self.diffableImageSource.apply(snapshot)
                }
            }
        }
        if !changes.newImageURLs.isEmpty {
            let newImageNames = changes.newImageURLs.map { $0.lastPathComponent }
            document.createImageItemsAsynchronously(with: newImageNames) { newItems in
                guard let newItems = newItems else { return }
                DispatchQueue.main.async {
                    var snapshot = self.diffableImageSource.snapshot()
                    snapshot.appendItems(newItems)
                    self.diffableImageSource.apply(snapshot)
                }
            }
        }
    }
    
    private func printDocumentState(for document: Document) {
        if document.documentState == .normal {
            print("documentState: [normal]" )
            return
        }
        var readableStrings = [String]()
        if document.documentState.contains(.inConflict) {
            readableStrings.append("inConflict")
        }
        if document.documentState.contains(.editingDisabled) {
            readableStrings.append("editingDisabled")
        }
        if document.documentState.contains(.progressAvailable) {
            readableStrings.append("progressAvailable")
        }
        if document.documentState.contains(.savingError) {
            readableStrings.append("savingError")
        }
        if document.documentState.contains(.closed) {
            readableStrings.append("closed")
        }
        print("documentState: \(readableStrings)")
    }
}

