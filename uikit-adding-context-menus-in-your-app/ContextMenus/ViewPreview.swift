/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UITargetedPreview context menu example for UIView.
*/

import UIKit

class ViewPreview: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: It's important that userInteractionEnabled is set to true for context menu to work on this view.
        let interaction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(interaction)
    }

}

// MARK: - ContextMenu

extension ViewPreview: ContextMenu {
    
    func performInspect() {
        Swift.debugPrint("preview inspect")
    }
    func performDuplicate() {
        Swift.debugPrint("preview duplicate")
    }
    func performDelete() {
        Swift.debugPrint("preview delete")
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

extension ViewPreview: UIContextMenuInteractionDelegate {
    
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(  identifier: nil,
                                            previewProvider: nil,
                                            actionProvider: { suggestedActions in
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction()
            let duplicateAction = self.duplicateAction()
            let deleteAction = self.deleteAction()
                                                
            return UIMenu(title: NSLocalizedString("", comment: ""),
                          children: [inspectAction, duplicateAction, deleteAction])
        })
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
        let visibleRect = imageView.bounds.insetBy(dx: -15, dy: -15)
        let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 10.0)
        parameters.backgroundColor = UIColor.systemTeal
        parameters.visiblePath = visiblePath
        return UITargetedPreview(view: imageView, parameters: parameters)
    }
    
}
