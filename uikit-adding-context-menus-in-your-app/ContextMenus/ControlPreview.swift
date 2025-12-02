/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Preview context menu example for UIControl.
*/

import UIKit

class ControlPreview: UIViewController {
    
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

extension ControlPreview: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
        return UIContextMenuConfiguration(identifier: nil, // Optional unique identifier. If omitted, an NSUUID will be generated.
                                          previewProvider: nil, // Optional preview view controller provider block.
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
    
    // Called when the interaction begins. Return a UITargetedPreview describing the desired highlight preview.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }

    /** Called when the interaction is about to dismiss. Return a UITargetedPreview describing the desired dismissal target.
        The interaction will animate the presented menu to the target. Use this to customize the dismissal animation.
    */
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }
    
    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        let visibleRect = buttonMenu.bounds.insetBy(dx: -15, dy: -15)
        let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 10.0)
        parameters.visiblePath = visiblePath
        parameters.backgroundColor = UIColor.systemTeal
       
        return UITargetedPreview(view: buttonMenu, parameters: parameters)
    }
    
}

// MARK: - ContextMenu

extension ControlPreview: ContextMenu {

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
