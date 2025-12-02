/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to remove the association from BrandXAccessory.
*/
import UIKit
import NetworkExtension

final class SetupRemoveHotspotViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var instruction: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Remove Network Configuration"
    }
    
    // MARK: - IBActions
    
    @IBAction func removeConfiguration() {
        
        guard let accessoryNetwork = DeviceNetworkManager.shared.accessoryNetwork else {
            instruction.text = "Error accessing accessory network infomation"
            return
        }
        
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: accessoryNetwork.accessorySSID)
        instruction.text = "Check your Wi-Fi networks in Settings to verify removal of \(accessoryNetwork.accessorySSID)"
    }
}
