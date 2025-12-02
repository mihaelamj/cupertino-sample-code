/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to confirm the association with BrandXAccessory.
*/
import UIKit

final class SetupConfirmHotspotViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var nextAction: UIButton!
    @IBOutlet private weak var instruction: UILabel!
    
    // MARK: - Private Variables
    
    private var didConfirmHotspotNetwork = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Confirm the Accessory Network"
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(wentIntoBackground),
                                               name: UIScene.willDeactivateNotification,
                                               object: nil)
        // Start location updates in preparation for capturing network information.
        LocationManager.shared.startLocationManager()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - IBActions
    
    @IBAction func confirmHotspotNetworkInfo() {
        
        if didConfirmHotspotNetwork {
            LocationManager.shared.stopLocationManager()
            if let sendNetworkDataVC = storyBoard.instantiateViewController(identifier: sendNetworkDataVCStoryBoardIdentifier)
                as? SetupSendDataViewController {
                self.navigationController?.pushViewController(sendNetworkDataVC, animated: true)
                return
            }
        }
        
        instruction.text = "Location Manager Authorized, Getting SSID"
        DeviceNetworkManager.shared.associatedSSIDs(completion: { associatedSSIDs in
            
            guard !associatedSSIDs.isEmpty, let accessoryNetwork = DeviceNetworkManager.shared.accessoryNetwork else {
                self.instruction.text = "No SSIDs were captured to confirm the BrandXAccessory Network"
                return
            }
            self.instruction.text = "SSID: \(associatedSSIDs[0])"
            if associatedSSIDs[0] == accessoryNetwork.accessorySSID {
                self.didConfirmHotspotNetwork = true
                self.nextAction.setTitle("Next", for: .normal)
            } else {
                self.instruction.text = "SSID: \(associatedSSIDs[0]), does not match: \(accessoryNetwork.accessorySSID).  Check your connection."
            }
        })
    }
}
