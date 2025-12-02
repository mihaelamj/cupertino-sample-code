/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Titled context menu example for UITableView.
*/

import UIKit

class TableViewTitled: BaseTableViewTestViewController {

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(  identifier: nil,
                                            previewProvider: nil,
                                            actionProvider: { suggestedActions in
            // Context menu with title.
                                                
            // Use the IndexPathContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction(indexPath)
            let duplicateAction = self.duplicateAction(indexPath)
            let deleteAction = self.deleteAction(indexPath)
                                                
            return UIMenu(title: NSLocalizedString("TableViewTitle", comment: ""),
                          children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
}

extension TableViewTitled: IndexPathContextMenu {
    
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
