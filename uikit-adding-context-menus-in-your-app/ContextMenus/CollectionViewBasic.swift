/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Basic context menu example for UICollectionView.
*/

import UIKit

class CollectionViewBasic: BaseCollectionViewTestViewController {

    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let inspectAction = self.inspectAction(indexPath)
            let duplicateAction = self.duplicateAction(indexPath)
            let deleteAction = self.deleteAction(indexPath)
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        }
    }
    
}

// MARK: - IndexPathContextMenu

extension CollectionViewBasic: IndexPathContextMenu {
    
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
