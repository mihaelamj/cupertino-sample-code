/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for showing error and status messages.
*/

import Cocoa

class MessagesViewController: NSViewController {
    // MARK: - Properties
    
    /// The message to display.
    var message: String?
    
    /// The system uses this to display a message.
    @IBOutlet fileprivate weak var messageLabel: NSTextField!
    
    // MARK: - View Life Cycle
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if let message = message {
            messageLabel.stringValue = message
        }
    }
}

