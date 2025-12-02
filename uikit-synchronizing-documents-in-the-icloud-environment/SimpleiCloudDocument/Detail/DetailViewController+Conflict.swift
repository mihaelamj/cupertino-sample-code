/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of DetailViewController that handles document conflicts.
*/

import UIKit

extension DetailViewController {
    // This is the action handler of the Conflicts button. Resolve the conflicts and update the UI.
    // For demo purpose, this sample simply makes the latest version the winner.
    // Real-world apps may consider a more sophisticated strategy.
    // See the following link for more discussion:
    // <https://developer.apple.com/documentation/uikit/uidocument#1658506>
    //
    @IBAction func handleConflicts(_ sender: Any) {
        guard let document = document, document.documentState.contains(.inConflict) else {
            handleConflictsItem.isEnabled = false
            return
        }
        
        let revertDocument: (Bool) -> Void = { shouldRevert in
            let message = "The lastest version won. The other versions were removed."
            let alert = UIAlertController(title: "Conflicts Resolved",
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))

            guard shouldRevert else {
                self.present(alert, animated: true)
                return
            }
            
            self.spinner.startAnimating()
            document.revert(toContentsOf: document.fileURL) {_ in
                self.spinner.stopAnimating()
                self.present(alert, animated: true)
            }
        }
        
        spinner.startAnimating()
        resolveConflictsAsynchronously(document: document) { shouldRevert in
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                revertDocument(shouldRevert)
            }
        }
    }

    // Resolve conflicts asynchronously because coordinated writing may take a long time.
    // Version information is a kind of document metadata, which needs coordinated access in the iCloud environment.
    // The completion handler runs in a secondary queue, so clients should dispatch their code appropriately.
    //
    private func resolveConflictsAsynchronously(document: Document, completionHandler: ((Bool) -> Void)?) {
        DispatchQueue.global().async {
            NSFileCoordinator().coordinate(writingItemAt: document.fileURL,
                                           options: .contentIndependentMetadataOnly, error: nil) { newURL in
                let shouldRevert = self.pickLatestVersion(for: newURL)
                completionHandler?(shouldRevert)
            }
        }
    }

    // Make the latest version current and remove the others.
    //
    private func pickLatestVersion(for documentURL: URL) -> Bool {
        guard let versionsInConflict = NSFileVersion.unresolvedConflictVersionsOfItem(at: documentURL),
              let currentVersion = NSFileVersion.currentVersionOfItem(at: documentURL) else {
            return false
        }
        var shouldRevert = false
        var winner = currentVersion
        for version in versionsInConflict {
            if let date1 = version.modificationDate, let date2 = winner.modificationDate,
               date1 > date2 {
                winner = version
            }
        }
        if winner != currentVersion {
            do {
                try winner.replaceItem(at: documentURL)
                shouldRevert = true
            } catch {
                print("Failed to replace version: \(error)")
            }
        }
        do {
            try NSFileVersion.removeOtherVersionsOfItem(at: documentURL)
        } catch {
            print("Failed to remove other versions: \(error)")
        }
        return shouldRevert
    }
}
