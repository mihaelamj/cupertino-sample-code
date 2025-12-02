/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The accessory delegate for the service detail view controller.
*/

import HomeKit

extension AccessorySettings: HMAccessoryDelegate {
    /// Handles characteristic updates.
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        guard service == self.service else { return }
        
        // Find the cell that displays this characteristic.
        guard let row = characteristics.firstIndex(of: characteristic),
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? CharacteristicCell
            else { return }
        
        // Tell the cell to refresh using the characteristic it already knows about.
        cell.redrawValueLabel()
        cell.redrawControls(animated: true)
    }
}
