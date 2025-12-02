/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller which is always shown in dark mode, regardless of whether the device is in light or dark mode.
*/

import UIKit

class AlwaysDarkViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        // DARK MODE ADOPTION: This is an example of how a view
        // controller's overrideUserInterfaceStyle property can be set
        // to force it to have a specific style, regardless of the style
        // used by the system or by its parent view controller or
        // presentation controller.

        self.overrideUserInterfaceStyle = .dark
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        // Do the same when the view controller is created from
        // a storyboard.

        self.overrideUserInterfaceStyle = .dark
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
