/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The home delegate for the accessory list.
*/

import HomeKit

/// Handle the home delegate callbacks.
extension AccessoryList: HMHomeDelegate {
    
    func homeDidUpdateName(_ home: HMHome) {
        guard home == self.home else { return }
        
        title = home.name
    }

    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        guard home == self.home else { return }
        
        // Make sure the new accessory generates callbacks to the home store.
        accessory.delegate = HomeStore.shared

        reloadData()
    }
    
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        for service in accessory.services {
            if let item = kilgoServices.firstIndex(of: service) {
                let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? AccessoryCell
                cell?.roomLabel.text = room.name
            }
        }
    }
    
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        guard home == self.home else { return }
        navigationController?.popToRootViewController(animated: true)
        reloadData()
    }
    
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        for cell in collectionView.visibleCells {
            (cell as? AccessoryCell)?.roomLabel.text = room.name
        }
    }
    
    func home(_ home: HMHome, didEncounterError error: Error, for accessory: HMAccessory) {
        print(error.localizedDescription)
    }
}
