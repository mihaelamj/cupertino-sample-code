/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that handles document management operations like
 creating, opening, and saving documents.
*/

import UIKit
import UniformTypeIdentifiers

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    var transitionController: UIDocumentBrowserTransitionController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        localizedCreateDocumentActionTitle = "New Markdown Document"
    }
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController,
        didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, ImportMode) -> Void) {
        let prompt = UIAlertController(title: "New Document", message: nil, preferredStyle: .alert)
        prompt.addTextField { $0.placeholder = "Document Name" }
        prompt.addAction(UIAlertAction(title: "Create", style: .default) { [unowned prompt] _ in
            if let name = prompt.textFields![0].text {
                let tempDir = FileManager.default.temporaryDirectory
                let tempUrl = tempDir.appendingPathComponent("\(name).md")
                let newDoc = MarkdownDocument(fileURL: tempUrl)
                
                newDoc.save(to: tempUrl, for: .forCreating) { saveSuccess in
                    if saveSuccess {
                        newDoc.close { closeSuccess in
                            if closeSuccess {
                                // Closing success, so move the newly created
                                // document from its temporary location to
                                // the current directory.
                                importHandler(tempUrl, .move)
                            } else {
                                // Closing failure, so log an error and
                                // cancel file creation.
                                importHandler(nil, .none)
                            }
                        }
                    }
                    
                }
            } else {
                importHandler(nil, .none)
            }
        })
        prompt.addAction(UIAlertAction(title: "Cancel", style: .destructive) { _ in
            // The user taps Cancel, so cancel file creation.
            importHandler(nil, .none)
        })
        present(prompt, animated: true)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        if let sourceURL = documentURLs.first {
            presentDocument(sourceURL)
        }
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        presentDocument(destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        let prompt = UIAlertController(title: nil, message: "Failed to open document", preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Ok", style: .default) { _ in })
        present(prompt, animated: true)
    }
    
    // MARK: Document Presentation

    func presentDocument(_ documentURL: URL) {
        let document = MarkdownDocument(fileURL: documentURL)
        let splitVC = SplitViewController(document: document)

        splitVC.transitioningDelegate = self
        splitVC.modalPresentationStyle = .fullScreen
        splitVC.editorViewController.documentBrowser = self

        transitionController = transitionController(forDocumentAt: documentURL)
        transitionController?.targetView = splitVC.editorViewController.navigationController?.view

        self.present(splitVC, animated: true)
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
}
