/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simplge, generic view controller with a text view
*/

import UIKit

class SimpleTextDisplayViewController: UIViewController {
    var textToDisplay: String?
    @IBOutlet weak var textView: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = textToDisplay
    }
}
