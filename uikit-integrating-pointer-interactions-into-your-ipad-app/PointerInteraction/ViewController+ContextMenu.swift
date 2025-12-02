/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contextual menu support for shape view in this view controller.
*/

import UIKit

extension ViewController: UIContextMenuInteractionDelegate {
    
    /**
    Context menus open with the following:
        Standard context menu with preview -
            Touchscreen touch and hold.
            Trackpad touch and hold on the primary button.
        Light-weight context menu without preview -
            ControlKey + Touchscreen tap.
            ControlKey + trackpad primary button click.
            ControlKey + trackpad primary button click (tap-to-click).
            Trackpad secondary button click.
            Trackpad secondary button click (tap-to-click).
    */
    
    func makeContextMenu(shapeView: ShapeView) -> UIMenu {
        
        // Come up with descriptive titles for the context menu items based on the kind of shape.
        var shapeTitle = NSLocalizedString("SquareTitle", comment: "")
        if shapeView is TriangleShapeView {
            shapeTitle = NSLocalizedString("TriangleTitle", comment: "")
        } else if shapeView is OvalShapeView {
            shapeTitle = NSLocalizedString("OvalTitle", comment: "")
        } else if shapeView is RoundrectShapeView {
            shapeTitle = NSLocalizedString("RoundedRectTitle", comment: "")
        }
        shapeTitle += " "
        
        let importCmd =
            UIAction(title: shapeTitle + NSLocalizedString("ImportTitle", comment: ""),
                     image: UIImage(systemName: "square.and.arrow.down")) { action in
                // Perform import.
            }
        let exportCmd =
            UIAction(title: shapeTitle + NSLocalizedString("ExportTitle", comment: ""),
                     image: UIImage(systemName: "square.and.arrow.up")) { action in
                // Perform export.
            }
        let archiveCmd =
            UIAction(title: shapeTitle + NSLocalizedString("ArchiveTitle", comment: ""),
                     image: UIImage(systemName: "archivebox")) { action in
                // Perform archive.
            }
        
        // Return a UIMenu with all of the actions as children.
        return UIMenu(title: "", children: [importCmd, exportCmd, archiveCmd])
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if let shapeView = interaction.view as? ShapeView {
            return shapeView.targetedPreview()
        } else {
            return nil
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let shapeView = interaction.view as? ShapeView else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return self.makeContextMenu(shapeView: shapeView)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionCommitAnimating) {

        // User tapped somewhere in the preview.
        // Obtain the view controller from the animator to perform a specific action once the commit animation is done.
        animator.addCompletion {
            /*if let viewController = animator.previewViewController {
                //..
            }*/
        }
    }
}
