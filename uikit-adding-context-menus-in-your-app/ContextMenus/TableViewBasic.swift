/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Basic context menu example for UITableView.
*/

import UIKit

class TableViewBasic: BaseTableViewTestViewController {
    
    func performInspect(_ indexPath: IndexPath) {
        Swift.debugPrint("inspect: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDuplicate(_ indexPath: IndexPath) {
        Swift.debugPrint("duplicate: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDelete(_ indexPath: IndexPath) {
        Swift.debugPrint("delete: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }

    // MARK: - UITableViewDelegate

    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
                suggestedActions in
            let inspectAction =
                UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                         image: UIImage(systemName: "arrow.up.square")) { action in
                    self.performInspect(indexPath)
                }
            let duplicateAction =
                UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                         image: UIImage(systemName: "plus.square.on.square")) { action in
                    self.performDuplicate(indexPath)
                }
            let deleteAction =
                UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                         image: UIImage(systemName: "trash"),
                         attributes: .destructive) { action in
                    self.performDelete(indexPath)
                }
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
}
