/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lets the user pick a room for an accessory.
*/

import UIKit
import HomeKit

class RoomPicker: UITableViewController {

    /// The rooms to choose from.
    var rooms = [HMRoom]()
    
    /// The home holding the rooms.
    var home: HMHome? {
        didSet {
            rooms = []
            guard let home = home else { rooms = []; return }
            rooms = [home.roomForEntireHome()] + home.rooms
            selectedRow = roomRow
        }
    }
    
    /// The service which lives in one of the rooms.
    var service: HMService? {
        didSet {
            selectedRow = roomRow
        }
    }
    
    /// The row of the selected room before any changes.
    var roomRow: Int? {
        guard let room = service?.accessory?.room else { return nil }
        return rooms.firstIndex(of: room)
    }
    
    /// The row the user has selected, starting as the initial room row.
    var selectedRow: Int?
    
    /// Registers interest in home delegate callbacks.
    override func viewDidLoad() {
        super.viewDidLoad()
        HomeStore.shared.addHomeDelegate(self)
    }
    
    /// Deregisters interest in home delegate callbacks.
    deinit {
        HomeStore.shared.removeHomeDelegate(self)
    }
    
    /// Calls on the home store to save changes, if any.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if let row = selectedRow,
            let accessory = service?.accessory,
            let home = home,
            selectedRow != roomRow {
            
            HomeStore.shared.move(accessory, in: home, to: rooms[row])
        }
    }
    
    /// Asks the user to supply a name for a new room, and then tries to create the room.
    @IBAction func addRoom(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add a Room",
                                      message: "Add a new room to the home.",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Name" }
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            if let name = alert.textFields?[0].text {
                self.home?.addRoom(withName: name) { room, error in
                    if let error = error {
                        print("Error adding room: \(error)")
                    } else if let home = self.home, let room = room {
                        HomeStore.shared.home(home, didAdd: room)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomCell", for: indexPath)

        // Fill in the name and check the selected row.
        cell.textLabel?.text = rooms[indexPath.row].name
        cell.accessoryType = indexPath.row == selectedRow ? .checkmark : .none

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Turn all the check marks off.
        tableView.visibleCells.forEach { $0.accessoryType = .none }

        // Turn exactly one back on.
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Remember which one was selected.
        selectedRow = indexPath.row
    }

    // Enables the deletion of any room except the Default Room, which always appears first.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath != IndexPath(row: 0, section: 0)
    }
    
    // Deletes a room.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let home = home {
            let room = rooms[indexPath.row]
            home.removeRoom(room) { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    HomeStore.shared.home(home, didRemove: room)
                }
            }
        }
    }
}
