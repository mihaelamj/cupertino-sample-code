/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to capture associated network information.
*/
import UIKit

final class SetupNetworkInfoViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var nextAction: UIButton!
    @IBOutlet private weak var instruction: UILabel!
    
    // MARK: - Private Variables
    
    private var didFindAssociatedNetwork = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Get Network Info"
        
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
    
    @IBAction func getNetworkInfo() {
        
        if didFindAssociatedNetwork {
            LocationManager.shared.stopLocationManager()
            if let hotspotVC = storyBoard.instantiateViewController(identifier: hotspotConnectionVCStoryBoardIdentifier)
                as? SetupHotspotConnectViewController {
                self.navigationController?.pushViewController(hotspotVC, animated: true)
                return
            }
        }
        instruction.text = "Location Manager Authorized, Getting SSID"
        DeviceNetworkManager.shared.associatedSSIDs(completion: { associatedSSIDs in
            if !associatedSSIDs.isEmpty {
                let associatedSSID = associatedSSIDs[0]
                // Set the originalAssociatedSSID to direct the user back to this SSID when communication with the accessory finishes.
                DeviceNetworkManager.shared.setOriginalAssociatedSSID(originalAssociatedSSID: associatedSSID)
                self.instruction.text = "Network SSID: \(associatedSSID)"
                self.didFindAssociatedNetwork = true
                self.nextAction.setTitle("Next", for: .normal)
            }
        })
    }
}
