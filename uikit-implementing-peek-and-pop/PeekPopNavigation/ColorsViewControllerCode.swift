/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A subclass of `ColorsViewControllerBase` that adds support for Peek and Pop with code by calling
 registerForPreviewing(with:sourceView:) and implementing UIViewControllerPreviewingDelegate.
*/

import UIKit

class ColorsViewControllerCode: ColorsViewControllerBase, UIViewControllerPreviewingDelegate {

    // MARK: - View life cycle

    /// - Tag: RegisterForPreviewing
    override func viewDidLoad() {
        super.viewDidLoad()

        registerForPreviewing(with: self, sourceView: tableView)
    }

    // MARK: - View controller previewing delegate

    /// - Tag: ViewControllerForLocation
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // First, get the index path and view for the previewed cell.
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath)
            else { return nil }

        // Enable blurring of other UI elements, and a zoom in animation while peeking.
        previewingContext.sourceRect = cell.frame

        // Create and configure an instance of the color item view controller to show for the peek.
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "ColorItemViewController") as? ColorItemViewController
            else { preconditionFailure("Expected a ColorItemViewController") }

        // Pass over a reference to the ColorData object and the specific ColorItem being viewed.
        viewController.colorData = colorData
        viewController.colorItem = colorData.colors[indexPath.row]

        return viewController
    }

    /// - Tag: ViewControllerToCommit
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Push the configured view controller onto the navigation stack.
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }

}
