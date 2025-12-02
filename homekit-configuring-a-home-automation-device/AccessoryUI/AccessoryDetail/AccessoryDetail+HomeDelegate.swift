/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The home delegate for the accessory detail view.
*/

import HomeKit

/// Handle the home delegate callbacks.
extension AccessoryDetail: HMHomeDelegate {
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        reloadData()
    }
    
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        reloadData()
    }
}
