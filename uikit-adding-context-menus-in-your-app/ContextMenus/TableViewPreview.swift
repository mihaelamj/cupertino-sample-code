/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UITargetedPreview context menu example for UITableView.
*/

import UIKit

class TableViewPreview: BaseTableViewTestViewController {

    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        let identifierString = NSString(string: "\(indexPath.row)")
        return UIContextMenuConfiguration(identifier: identifierString, previewProvider: nil, actionProvider: { suggestedActions in
            // Use the IndexPathContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction(indexPath)
            let duplicateAction = self.duplicateAction(indexPath)
            let deleteAction = self.deleteAction(indexPath)
            return UIMenu(title: "",
                          children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
    // Called when the interaction begins. Return a UITargetedPreview to override the default preview created by the table view.
    override func tableView(_ tableView: UITableView,
                            previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }

    /** Called when the interaction is about to dismiss. Return a UITargetedPreview describing the desired dismissal target.
        The interaction will animate the presented menu to the target. Use this to customize the dismissal animation.
    */
    override func tableView(_ tableView: UITableView,
                            previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {

        // Ensure we can get the expected identifier.
        if let configIdentifier = configuration.identifier as? String {
            guard let row = Int(configIdentifier) else { return nil }
            
            // Get the cell for the index of the model.
            guard let cell = tableView.cellForRow(at: .init(row: row, section: 0)) else { return nil }
            
            let parameters = UIPreviewParameters()
            //parameters.backgroundColor = .clear // This will make the view transparent to everything underneath it.

            // Return a targeted preview using our cell's imageView and parameters.
            return UITargetedPreview(view: cell.imageView!, parameters: parameters)
        } else {
            return nil
        }
    }

}

extension TableViewPreview: IndexPathContextMenu {
    
    func performInspect(_ indexPath: IndexPath) {
        Swift.debugPrint("preview inspect: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDuplicate(_ indexPath: IndexPath) {
        Swift.debugPrint("preview duplicate: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    func performDelete(_ indexPath: IndexPath) {
        Swift.debugPrint("preview delete: \(dataSource.itemIdentifier(for: indexPath)!.name)")
    }
    
}

