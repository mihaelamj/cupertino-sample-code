/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The home delegate for the room picker.
*/

import HomeKit

/// Handle the home delegate callbacks.
extension RoomPicker: HMHomeDelegate {
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        guard home == self.home, accessory == service?.accessory else { return }
        
        // Record the row of the newly selected room.
        selectedRow = roomRow
        
        // Reset the checkmarks
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = indexPath.row == selectedRow ? .checkmark : .none
        }
    }
    
    func home(_ home: HMHome, didAdd room: HMRoom) {
        guard home == self.home else { return }
        
        // Add a row at the end.
        let indexPaths = [IndexPath(row: rooms.count, section: 0)]
        rooms.append(room)
        tableView.insertRows(at: indexPaths, with: .fade)
    }

    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        guard home == self.home else { return }
        
        // Rewrite all the visible room names.
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            let cell = tableView.cellForRow(at: indexPath)
            cell?.textLabel?.text = rooms[indexPath.row].name
        }
    }
    
    func home(_ home: HMHome, didRemove room: HMRoom) {
        guard home == self.home else { return }
        
        // Delete the appropriate row.
        if let row = rooms.firstIndex(of: room) {
            let indexPaths = [IndexPath(row: row, section: 0)]
            rooms.remove(at: row)
            tableView.deleteRows(at: indexPaths, with: .fade)
        }
    }
}
