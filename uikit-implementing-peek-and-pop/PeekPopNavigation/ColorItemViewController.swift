/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller to show a preview of a color and provide two alternative techniques for
 starring/unstarring and deleting it. The first technique is an action method linked from the
 navigation bar in the storyboard and the second is to support Peek Quick Actions by overriding
 the previewActionItems property.
*/

import UIKit

class ColorItemViewController: UIViewController {

    var colorData: ColorData?
    var colorItem: ColorItem?

    @IBOutlet var starButton: UIBarButtonItem!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let colorItem = colorItem
            else { preconditionFailure("Expected a color item") }

        title = colorItem.name
        view.backgroundColor = colorItem.color
        starButton.title = starButtonTitle()
    }

    // MARK: - Action methods

    @IBAction func toggleStar() {
        guard let colorItem = colorItem
            else { preconditionFailure("Expected a color item") }

        colorItem.starred.toggle()

        starButton.title = starButtonTitle()
    }

    @IBAction func delete() {
        guard let colorData = colorData
            else { preconditionFailure("Expected a reference to the color data container") }

        guard let colorItem = colorItem
            else { preconditionFailure("Expected a color item") }

        colorData.delete(colorItem)

        // The color no longer exists so dismiss this view controller.
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Supporting Peek Quick Actions

    /// - Tag: PreviewActionItems
    override var previewActionItems: [UIPreviewActionItem] {
        let starAction = UIPreviewAction(title: starButtonTitle(), style: .default, handler: { [unowned self] (_, _) in
            guard let colorItem = self.colorItem
                else { preconditionFailure("Expected a color item") }

            colorItem.starred.toggle()
        })

        let deleteAction = UIPreviewAction(title: "Delete", style: .destructive) { [unowned self] (_, _) in
            guard let colorData = self.colorData
                else { preconditionFailure("Expected a reference to the color data container") }

            guard let colorItem = self.colorItem
                else { preconditionFailure("Expected a color item") }

            colorData.delete(colorItem)
        }

        return [ starAction, deleteAction ]
    }

    // MARK: - UI helper methods

    func starButtonTitle() -> String {
        guard let colorItem = colorItem
            else { preconditionFailure("Expected a color item") }

        return colorItem.starred ? "Unstar" : "Star"
    }

}
