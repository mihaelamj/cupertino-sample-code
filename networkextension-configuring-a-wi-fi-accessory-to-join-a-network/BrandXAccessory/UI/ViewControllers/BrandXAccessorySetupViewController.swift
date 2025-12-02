/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that presents Internet Sharing information and status.
*/
import Cocoa
import CoreWLAN

final class BrandXAccessorySetupViewController: BrandXAccessoryBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var ssid: NSTextField!
    @IBOutlet private weak var passphrase: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ssid.stringValue = Constants.accessorySSID
        passphrase.stringValue = Constants.accessoryPassphrase
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateStatusLabel()
    }
    
    // MARK: - IBActions
    
    @IBAction func nextButton(sender: AnyObject) {
        if let configureVC = storyBoard.instantiateController(withIdentifier: "ConfigureViewController") as? BrandXAccessoryConfigureViewController {
            if let window = view.window {
                configureVC.view.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.height)
                window.contentViewController = configureVC
            }
        }
    }
    
    // MARK: - Instance Methods
    
    func updateStatusLabel() {
        // Check whether (Wi-Fi) Internet Sharing is in an enabled state.
        if CWWiFiClient.shared().interface()?.interfaceMode() == .some(.hostAP) {
            status = "Internet Sharing Started"
        } else {
            status = "Internet Sharing NOT Started"
        }
    }
}
