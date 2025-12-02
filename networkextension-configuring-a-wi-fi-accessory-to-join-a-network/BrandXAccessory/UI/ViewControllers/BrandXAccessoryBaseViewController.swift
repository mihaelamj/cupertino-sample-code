/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base view controller for all view controllers in BrandXAccessory.
*/

import Cocoa

class BrandXAccessoryBaseViewController: NSViewController {
    
    // MARK: - Public Constants
    
    let storyBoard = NSStoryboard(name: "Main", bundle: nil)
    @IBOutlet private weak var statusLabel: NSTextField!
    
    var status: String {
        get {
            statusLabel.stringValue
        }
        set {
            statusLabel.stringValue = newValue
        }
    }
}
