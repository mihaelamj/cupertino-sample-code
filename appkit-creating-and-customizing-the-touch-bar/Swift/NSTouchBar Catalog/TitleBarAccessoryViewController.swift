/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for the title bar accessory that contains the Set Background button.
*/

import Cocoa

class TitleBarAccessoryViewController: NSTitlebarAccessoryViewController {
    var openingViewController: BackgroundImagesViewController!

    @IBAction func presentPhotos(sender: Any) {
        if openingViewController == nil {
            if let imagesViewController =
                self.storyboard?.instantiateController(
                    withIdentifier: NSStoryboard.Name("BackgroundImagesViewController")) as? BackgroundImagesViewController {
                openingViewController = imagesViewController
            }
        }
        // Show the BackgroundImagesViewController as a popover.
        present(openingViewController, asPopoverRelativeTo: self.view.bounds, of: view, preferredEdge: .minY, behavior: .transient)
    }

}
