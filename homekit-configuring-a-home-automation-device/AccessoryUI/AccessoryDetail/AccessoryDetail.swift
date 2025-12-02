/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detailed view of a single accessory.
*/

import UIKit
import HomeKit

class AccessoryDetail: UITableViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var firmwareLabel: UILabel!
    
    /// The service that this detail view shows. The UI refers to `HMService`
    /// instances as 'accessories' to be consistent with Home app terminology.
    var service: HMService?
    
    /// The home of which the service is a part, used for room picking and accessory removal.
    var home: HMHome?
    
    /// Resets the view data based on the current service.
    func reloadData() {
        title = service?.name ?? "Accessory Detail"
        nameLabel.text = service?.name
        roomLabel.text = service?.accessory?.room?.name
        modelLabel.text = service?.accessory?.model
        firmwareLabel.text = service?.accessory?.firmwareVersion
    }
    
    /// Registers this view controller to receive various delegate callbacks.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HomeStore.shared.addHomeDelegate(self)
        HomeStore.shared.addAccessoryDelegate(self)
        
        reloadData()
    }
    
    /// Deregisters this view controller as various kinds of delegate.
    deinit {
        HomeStore.shared.removeHomeDelegate(self)
        HomeStore.shared.removeAccessoryDelegate(self)
    }

    /// Prepares to show one of the child views of this view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? NameEditor {
            controller.service = service
            
        } else if let controller = segue.destination as? RoomPicker {
            controller.service = service
            controller.home = home

        } else if let controller = segue.destination as? AccessorySettings {
            controller.service = service
        }
    }
    
    /// Handles table view cell taps.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 2) {
            let alert = UIAlertController(title: "Remove Accessory",
                                          message: "Are you sure you want to remove this accessory?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
                if let accessory = self.service?.accessory,
                    let home = self.home {
                    HomeStore.shared.remove(accessory, from: home)
                }
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            present(alert, animated: true)
        }
    }
}
