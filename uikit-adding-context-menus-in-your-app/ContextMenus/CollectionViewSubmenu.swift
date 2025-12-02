/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Submenu context menu example for UICollectionView.
*/

import UIKit

class CollectionViewSubmenu: BaseCollectionViewTestViewController {
    
    // MARK: - UICollectionViewDelegate
  
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in

            // Context menu with submenu.
                                            
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction(indexPath)
            let duplicateAction = self.duplicateAction(indexPath)
            let deleteAction = self.deleteAction(indexPath)

            // Set up the edit menu (as a submenu).
            let editMenu = UIMenu(title: NSLocalizedString("EditTitle", comment: ""),
                                  children: [duplicateAction, deleteAction])
    
            /** Note:
                If you want to display the Edit submenu menu in the main part of the context menu, with a separator line, use:
            */
            /*let editMenu = UIMenu(title: NSLocalizedString("EditTitle", comment: ""),
                                  options: .displayInline,
                                  children: [duplicateAction, deleteAction])
            */
              
            return UIMenu(title: "", children: [inspectAction, editMenu])
        }
    }
    
}

// MARK: - IndexPathContextMenu

extension CollectionViewSubmenu: IndexPathContextMenu {
    
    func performInspect(_ indexPath: IndexPath) {
        Swift.debugPrint("inspect: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDuplicate(_ indexPath: IndexPath) {
        Swift.debugPrint("duplicate: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDelete(_ indexPath: IndexPath) {
        let alertController = UIAlertController(title: NSLocalizedString("DeleteConfirmTitle", comment: ""),
                                                message: nil,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OKTitle", comment: ""),
                                     style: .destructive) { (action: UIAlertAction) in
            Swift.debugPrint("Delete \(self.dataSource.itemIdentifier(for: indexPath)!.name)")
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CancelTitle", comment: ""),
                                         style: .cancel,
                                         handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
