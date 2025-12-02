/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates displaying text above the navigation bar.
*/

import UIKit

class NavigationPromptViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.prompt = NSLocalizedString("Navigation prompts appear at the top.", comment: "")
    }

}
