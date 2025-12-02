/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The accessory delegate for the accessory list.
*/

import HomeKit

extension AccessoryList: HMAccessoryDelegate {
    /// Handles characteristic value updates.
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if let item = kilgoServices.firstIndex(of: service) {
            let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? AccessoryCell
            cell?.redrawState()
        }
    }
    
    func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService) {
        if let item = kilgoServices.firstIndex(of: service) {
            let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? AccessoryCell
            cell?.nameLabel.text = service.name
        }
    }
}
