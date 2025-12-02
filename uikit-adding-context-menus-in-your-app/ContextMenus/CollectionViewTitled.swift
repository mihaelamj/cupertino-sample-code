/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Titled context menu example for UICollectionView.
*/

import UIKit

class CollectionViewTitled: BaseCollectionViewTestViewController {
    
    // MARK: - UICollectionViewDelegate
  
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // Context menu with title.
            
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction(indexPath)
            let duplicateAction = self.duplicateAction(indexPath)
            let deleteAction = self.deleteAction(indexPath)
            return UIMenu(title: NSLocalizedString("CollectionViewTitle", comment: ""),
                          children: [inspectAction, duplicateAction, deleteAction])
        }
    }
    
}

// MARK: - IndexPathContextMenu

extension CollectionViewTitled: IndexPathContextMenu {
    
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
