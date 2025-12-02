/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UITargetedPreview context menu example for UICollectionView.
*/

import UIKit

class CollectionViewPreview: BaseCollectionViewTestViewController {
    
    // MARK: - UICollectionViewDelegate
  
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
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
    
    // Called when the interaction begins. Return a UITargetedPreview describing the desired highlight preview.
    override func collectionView(_ collectionView: UICollectionView,
                                 previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }

    /** Called when the interaction is about to dismiss. Return a UITargetedPreview describing the desired dismissal target.
        The interaction will animate the presented menu to the target. Use this to customize the dismissal animation.
    */
    override func collectionView(_ collectionView: UICollectionView,
                                 previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {

        // Ensure we can get the expected identifier.
        if let configIdentifier = configuration.identifier as? String {
            guard let row = Int(configIdentifier) else { return nil }
            
            // Get the cell for the index of the model.
            guard let cell = collectionView.cellForItem(at: .init(row: row, section: 0)) else { return nil }
            
            let parameters = UIPreviewParameters()
            let visibleRect = cell.contentView.bounds.insetBy(dx: -10, dy: -10)
            let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 20.0)
            parameters.visiblePath = visiblePath
            parameters.backgroundColor = UIColor.systemTeal
            
            return UITargetedPreview(view: cell.contentView, parameters: parameters)
        } else {
            return nil
        }
    }
}

// MARK: - IndexPathContextMenu

extension CollectionViewPreview: IndexPathContextMenu {
    
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
