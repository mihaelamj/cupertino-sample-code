/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of MainViewController that provides interfaces for opening, creating, and removing a document.
*/

import Foundation

extension MainViewController {
    // An enumeration that presents the scopes of an iCloud container.
    // .documents: Points to the Documents folder in an iCloud container.
    // .data: Points to the Data folder an iCloud container.
    // Documents in the .documents scope behave differently from the other scopes in that
    // they appear in iCloud Drive if the app publishes the iCloud container, and in
    // Settings > Apple ID > iCloud > Manage Storage > SimpleiCloudDocument.
    //
    enum Scope: String {
        case documents = "Documents"
        case data = "Data"
    }
    
    // Checks if fileURL is in the .documents scope and returns true if yes.
    //
    func isDocumentScopeURL(_ fileURL: URL) -> Bool {
        guard let rootURL = metadataProvider?.containerRootURL else { return false }
        
        let documentsFolderPath = rootURL.appendingPathComponent(Scope.documents.rawValue).path
        return fileURL.path.hasPrefix(documentsFolderPath)
    }

    // Creates and returns a URL from the specified filename and scope.
    // Use "Untitled" if the filename is empty.
    //
    private func url(for fileName: String, scope: Scope) -> URL? {
        guard let rootURL = metadataProvider?.containerRootURL else { return nil }
        
        var url = rootURL.appendingPathComponent(scope.rawValue)
        let name = fileName.isEmpty ? "Untitled" : fileName
        url = url.appendingPathComponent(name, isDirectory: false)
        url = url.appendingPathExtension(Document.extensionName)
        return url
    }

    // Create a new document by calling save(to:for:completionHandler:) with .forCreating.
    // Create the intermediate directories if they don't exist.
    // Close the document after successfully creating it to avoid blocking other operations.
    //
    func createDocument(with fileName: String, scope: Scope, content: String, completionHandler: ((Bool) -> Void)?) {
        guard let fileURL = url(for: fileName, scope: scope) else {
            completionHandler?(false)
            return
        }
        
        do {
            let folderPath = fileURL.deletingLastPathComponent().path
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            completionHandler?(false)
            return
        }
        
        // save(to:for:completionHandler:) keeps the document open, so close the document after the saving finishes.
        // Keeping the document open prevents (blocks) others from coordinated writing it.
        //
        // Ignore the document saving error here because
        // Document's handleError method should have handled the document reading or saving error, if necessary.
        //
        let document = Document(fileURL: fileURL)
        document.save(to: fileURL, for: .forCreating) { _ in
            document.close { success in
                if !success {
                    print("Failed to close the document: \(fileURL)")
                }
                completionHandler?(success)
            }
        }
    }
    
    // Remove a document.
    //
    func removeDocument(at fileURL: URL) {
        DispatchQueue.global().async {
            NSFileCoordinator().coordinate(writingItemAt: fileURL, options: .forDeleting, error: nil) { newURL in
                do {
                    try FileManager.default.removeItem(atPath: newURL.path)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // Open a document in place.
    // If the passed-in URL is already in the data source, select the item and open it.
    // Otherwise, deselect the table view and open the URL directly in the detail view controller.
    //
    func openDocumentInPlace(url: URL) {
        if let indexPath = diffableMetadataSource.indexPath(for: MetadataItem(nsMetadataItem: nil, url: url)) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            performSegue(withIdentifier: SegueID.showDetail, sender: self)
            return
        }
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        performSegue(withIdentifier: SegueID.showDetail, sender: url)
    }
}
