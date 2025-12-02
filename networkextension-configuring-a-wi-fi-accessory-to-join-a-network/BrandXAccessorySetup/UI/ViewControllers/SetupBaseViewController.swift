/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base view controller for all view controllers in BrandXAccessory
*/

import UIKit

class SetupBaseViewController: UIViewController {
    
    // MARK: - Public constants
    
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    let networkInfoVCStoryBoardIdentifier = "NetworkInfo"
    let hotspotConnectionVCStoryBoardIdentifier = "HotspotConnection"
    let confirmHotspotVCStoryBoardIdentifier = "ConfirmHotspotNetwork"
    let sendNetworkDataVCStoryBoardIdentifier = "SendNetworkData"
    let removeHotspotVCStoryBoardIdentifier = "RemoveHotspot"
    
    // MARK: - Private Location Methods
    
    @objc
    func wentIntoBackground() {
        LocationManager.shared.stopLocationManager()
    }
}
