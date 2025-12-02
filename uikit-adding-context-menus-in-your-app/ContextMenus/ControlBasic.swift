/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Basic context menu example for UIControl.
*/

import UIKit

class ControlBasic: UIViewController {
    
    @IBOutlet var buttonMenu: UIButton!
    @IBOutlet var buttonMenuAsPrimary: UIButton!
    
    func menuHandler(action: UIAction) {
        Swift.debugPrint("Menu Action '\(action.title)'")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the button's context menu via UIContextMenuInteractionDelegate.
        let interaction = UIContextMenuInteraction(delegate: self)
        buttonMenu.addInteraction(interaction)
        
        // Setup the button's context menu directly.
        let inspectAction = self.inspectAction()
        let duplicateAction = self.duplicateAction()
        let deleteAction = self.deleteAction()
        buttonMenuAsPrimary.menu = UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        buttonMenuAsPrimary.showsMenuAsPrimaryAction = true
    }

    @IBAction func buttonAction(_: UIButton) {
        Swift.debugPrint("button action")
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ControlBasic: UIContextMenuInteractionDelegate {
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
                suggestedActions in
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction()
            let duplicateAction = self.duplicateAction()
            let deleteAction = self.deleteAction()
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {
    }
    
}

// MARK: - ContextMenu

extension ControlBasic: ContextMenu {

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
