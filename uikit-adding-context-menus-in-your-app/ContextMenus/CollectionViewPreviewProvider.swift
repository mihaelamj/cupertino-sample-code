/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Preview provider context menu example for UICollectionView.
*/

import UIKit

class CollectionViewPreviewProvider: BaseCollectionViewTestViewController {
    
    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
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
                let inspectAction = self.inspectAction(indexPath)
                let duplicateAction = self.duplicateAction(indexPath)
                let deleteAction = self.deleteAction(indexPath)
                return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
            })
            
        } else {
            return nil
        }
    }
    
    // Called when the interaction is about to "commit" in response to the user tapping the preview.
    override func collectionView(_ collectionView: UICollectionView,
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

extension CollectionViewPreviewProvider: IndexPathContextMenu {
    
    func performInspect(_ indexPath: IndexPath) {
        Swift.debugPrint("inspect: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDuplicate(_ indexPath: IndexPath) {
        Swift.debugPrint("duplicate: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDelete(_ indexPath: IndexPath) {
        Swift.debugPrint("delete: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    
}
