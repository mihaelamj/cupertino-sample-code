/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The accessory delegate for the accessory detail view.
*/

import HomeKit

/// Handle the accessory delegate callbacks.
extension AccessoryDetail: HMAccessoryDelegate {
    func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService) {
        reloadData()
    }
}
