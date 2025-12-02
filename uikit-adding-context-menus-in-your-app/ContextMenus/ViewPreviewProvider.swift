/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Preview provider context menu example for UIView.
*/

import UIKit

class ViewPreviewProvider: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: It's important that userInteractionEnabled is set to true for context menu to work on this view.
        let interaction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(interaction)
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

extension ViewPreviewProvider: UIContextMenuInteractionDelegate {
    
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            if let previewViewController =
                    self.storyboard?.instantiateViewController(identifier: "PreviewViewController") as? PreviewViewController {
                previewViewController.imageName = "image4"
                return previewViewController
            } else {
                return nil
            }
        }, actionProvider: { suggestedActions in
            // Use the ContextMenu protocol to produce the UIActions.
            let inspectAction = self.inspectAction()
            let duplicateAction = self.duplicateAction()
            let deleteAction = self.deleteAction()
            return UIMenu(title: "",
                          children: [inspectAction, duplicateAction, deleteAction])
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            Swift.debugPrint("User tapped the preview")
        }
    }
    
}

// MARK: - ContextMenu

extension ViewPreviewProvider: ContextMenu {
    
    func performInspect() {
        Swift.debugPrint("preview provider inspect")
    }
    func performDuplicate() {
        Swift.debugPrint("preview provider duplicate")
    }
    func performDelete() {
        Swift.debugPrint("preview provider delete")
    }
    
}
