/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Basic context menu example for UIView.
*/

import UIKit

class ViewBasic: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    func performInspect() {
        Swift.debugPrint("inspect")
    }
    func performDuplicate() {
        Swift.debugPrint("duplicate")
    }
    func performDelete() {
        Swift.debugPrint("delete")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Note: It's important that userInteractionEnabled is set to true for context menu to work on this view.
        let interaction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(interaction)
    }

}

// MARK: - UIContextMenuInteractionDelegate

extension ViewBasic: UIContextMenuInteractionDelegate {
    // Returns an action-based contextual menu, optionally incorporating the system-suggested actions.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
                suggestedActions in
            let inspectAction =
                UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                         image: UIImage(systemName: "arrow.up.square")) { action in
                    self.performInspect()
                }
                
            let duplicateAction =
                UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                         image: UIImage(systemName: "plus.square.on.square")) { action in
                    self.performDuplicate()
                }
                
            let deleteAction =
                UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                         image: UIImage(systemName: "trash"),
                         attributes: .destructive) { action in
                    self.performDelete()
                }
                                            
            return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
        })
    }
}
