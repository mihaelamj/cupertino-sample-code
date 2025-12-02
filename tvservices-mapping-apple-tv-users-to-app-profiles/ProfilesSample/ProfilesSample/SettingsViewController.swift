/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller with simple options to help use the app.
*/

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Settings"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        title = "Settings"
    }

    @IBAction func pickProfile(_ sender: UIButton!) {
        AppDelegate.shared.presentProfilePicker()
    }

    @IBAction func signOut(_ sender: Any) {
        AppDelegate.shared.signOut()
    }

    @IBAction func reset(_ sender: UIButton!) {
        AppDelegate.shared.resetPreferences()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.setCustomSpacing(60, after: titleLabel)
    }
}

