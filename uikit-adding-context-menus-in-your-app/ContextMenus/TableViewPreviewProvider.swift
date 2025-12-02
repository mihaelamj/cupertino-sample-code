/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Preview provider context menu example for UITableView.
*/

import UIKit

class TableViewPreviewProvider: BaseTableViewTestViewController {

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        if let cellItemIdentifier = dataSource.itemIdentifier(for: indexPath) {
            let identifier = NSString(string: "\(cellItemIdentifier.name)") // Use the image name for the identifier.
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: {
                if let previewViewController =
                        self.storyboard?.instantiateViewController(identifier: "PreviewViewController") as? PreviewViewController {
                    previewViewController.imageName = cellItemIdentifier.name
                    return previewViewController
                } else {
                    return nil
                }
            }, actionProvider: { suggestedActions in
                // Use the IndexPathContextMenu protocol to produce the UIActions.
                let inspectAction = self.inspectAction(indexPath)
                let duplicateAction = self.duplicateAction(indexPath)
                let deleteAction = self.deleteAction(indexPath)
                return UIMenu(title: "",
                              children: [inspectAction, duplicateAction, deleteAction])
            })
            
        } else {
            return nil
        }
    }

    // Called when the interaction is about to "commit" in response to the user tapping the preview.
    override func tableView(_ tableView: UITableView,
                            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                            animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            // Get the identifier to access the image name.
            guard let identifier = configuration.identifier as? String else { return }
            Swift.debugPrint("User tapped the preview with image: \(identifier)")
        }
    }

}

// MARK: - IndexPathContextMenu

extension TableViewPreviewProvider: IndexPathContextMenu {

    func performInspect(_ indexPath: IndexPath) {
        Swift.debugPrint("preview provider inspect: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDuplicate(_ indexPath: IndexPath) {
        Swift.debugPrint("preview provider duplicate: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDelete(_ indexPath: IndexPath) {
        Swift.debugPrint("preview provider delete: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
}

