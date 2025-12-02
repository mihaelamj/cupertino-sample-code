/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom NSButton subclass.
*/

import Cocoa

class ButtonSubclassViewController: ButtonBaseViewController {

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// - Tag: setAccessibilityLabel
        button.setAccessibilityLabel(NSLocalizedString("My label", comment: "label to use for this button"))
    }
    
}

