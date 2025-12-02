/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that acknowledges the iOS network's SSID and passphrase.
*/

import Cocoa

final class BrandXAccessoryDoneViewController: BrandXAccessoryBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var ssidValue: NSTextField!
    @IBOutlet private weak var passphraseValue: NSTextField!
    
    // MARK: - Public variables
    
    public var acquiredSSID = ""
    public var acquiredPassphrase = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ssidValue.stringValue = acquiredSSID
        passphraseValue.stringValue = acquiredPassphrase
        status = "Network SSID and Passphrase Received"
    }
    
}

