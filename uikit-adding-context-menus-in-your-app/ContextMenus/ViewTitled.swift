/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Titled context menu example for UIView.
*/

import UIKit

class ViewTitled: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: It's important that userInteractionEnabled is set to true for context menu to work on this view.
        let interaction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(interaction)
    }

}

// MARK: - ContextMenu

extension ViewTitled: ContextMenu {

    func performInspect() {
        Swift.debugPrint("inspect")
    }
    func performDuplicate() {
        Swift.debugPrint("duplicate")
    }
    func performDelete() {
        Swift.debugPrint("delete")
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

extension ViewTitled: UIContextMenuInteractionDelegate {
    
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(  identifier: nil,
                                            previewProvider: nil,
                                            actionProvider: { suggestedActions in
            // Context menu with title.
                                                
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction()
            let duplicateAction = self.duplicateAction()
            let deleteAction = self.deleteAction()
                                                
            return UIMenu(title: NSLocalizedString("ViewTitle", comment: ""),
                          children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
}

