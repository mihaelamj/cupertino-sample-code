/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Preview provider context menu example for UIControl.
*/

import UIKit

class ControlPreviewProvider: UIViewController {
    
    @IBOutlet var buttonMenu: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let interaction = UIContextMenuInteraction(delegate: self)
        buttonMenu.addInteraction(interaction)
    }

    @IBAction func buttonAction(_: UIButton) {
        Swift.debugPrint("button action")
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ControlPreviewProvider: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
        return UIContextMenuConfiguration(identifier: nil, // Optional unique identifier. If omitted, an NSUUID will be generated.
                                          previewProvider: {
                                              if let previewViewController =
                                                    self.storyboard?.instantiateViewController(
                                                          identifier: "ControlPreviewViewController") as? ControlPreviewViewController {
                                                previewViewController.title = self.buttonMenu.titleLabel!.text
                                                previewViewController.image = self.buttonMenu.image(for: .normal)
                                                    return previewViewController
                                              } else { return nil }
                                          },
                                          actionProvider: { // Action provider block called before context menu is presented.
                suggestedActions in // These are actions UIKit has accumulated from the responder chain.
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

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            Swift.debugPrint("User tapped the button preview")
        }
    }
    
}

// MARK: - ContextMenu

extension ControlPreviewProvider: ContextMenu {

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
