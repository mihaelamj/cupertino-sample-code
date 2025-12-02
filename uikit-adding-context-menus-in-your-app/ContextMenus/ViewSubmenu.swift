/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Submenu context menu example for UIView.
*/

import UIKit

class ViewSubmenu: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: It's important that userInteractionEnabled is set to true for context menu to work on this view.
        let interaction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(interaction)
    }

}

// MARK: - ContextMenu

extension ViewSubmenu: ContextMenu {
    
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

extension ViewSubmenu: UIContextMenuInteractionDelegate {
    
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(  identifier: nil,
                                            previewProvider: nil,
                                            actionProvider: { suggestedActions in
            // Context menu with submenu.
                                            
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction()
            let duplicateAction = self.duplicateAction()
            let deleteAction = self.deleteAction()

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
        })
    }
    
}
