/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to start association with BrandXAccessory.
*/
import UIKit
import NetworkExtension

final class SetupHotspotConnectViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var nextAction: UIButton!
    @IBOutlet private weak var instruction: UILabel!
    
    // MARK: - Private Variables
    
    private var accessoryNetworkManager: AccessoryNetworkManager?
    
    // MARK: - Public Variables
    
    public var didConnectToHotspot = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Associate with BrandXAccessory Network"
    }
    
    // MARK: - IBActions
    
    @IBAction func connectToHotspot() {
        
        if didConnectToHotspot {
            if let confirmHotspotVC = storyBoard.instantiateViewController(identifier: confirmHotspotVCStoryBoardIdentifier)
                as? SetupConfirmHotspotViewController {
                self.navigationController?.pushViewController(confirmHotspotVC, animated: true)
                return
            }
        } else if accessoryNetworkManager == nil {
            
            let accNetworkManager = AccessoryNetworkManager()
            accessoryNetworkManager = accNetworkManager
            accNetworkManager.delegate = self
            if let accessoryNetwork = DeviceNetworkManager.shared.accessoryNetwork {
                accNetworkManager.applyConfiguration(with: accessoryNetwork)
            }
        }
    }
}

// MARK: - AccessoryNetworkManagerDelegate Methods

extension SetupHotspotConnectViewController: AccessoryNetworkManagerDelegate {
    
    /// @function accessoryNetworkManagerDidUpdate
    /// @discussion Receives a notification when the state of AccessoryNetworkManager changes.
    func accessoryNetworkManagerDidUpdate(acessoryNetworkManager: AccessoryNetworkManager) {
        
        instruction.text = acessoryNetworkManager.status
        guard acessoryNetworkManager.isReady else {
            accessoryNetworkManager = nil
            return
        }
        didConnectToHotspot = true
        nextAction.setTitle("Next", for: .normal)
    }
}
