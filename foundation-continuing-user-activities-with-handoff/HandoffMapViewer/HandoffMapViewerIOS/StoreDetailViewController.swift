/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for showing details of a store and viewing/editing its favorite status.
*/

import UIKit

class StoreDetailViewController: UIViewController {

    var store: AppleStore? {
        didSet {
            updateUI()
        }
    }
    var storeDirectory: AppleStoreDirectory? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var storeNameLabel: UILabel!
    @IBOutlet weak var favoriteSwitch: UISwitch!
    @IBOutlet weak var addressLabel: UILabel!
    
    private func updateUI() {
        DispatchQueue.main.async {
            if let store = self.store {
                self.storeNameLabel?.text = store.name
                guard let address = store.placemark.postalAddress else {
                    self.addressLabel?.text = nil
                    return
                }
                self.addressLabel?.text = "\(address.subLocality) \(address.street)\n\(address.city), \(address.state)\n\(address.country)"
                if let storeDirectory = self.storeDirectory {
                    self.favoriteSwitch?.isOn = storeDirectory.isFavorite(store: store) ? true : false
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    @IBAction func handleFavoriteSwitchValueChanged() {
        if let store = store, let storeDirectory = storeDirectory {
            storeDirectory.setFavorite(self.favoriteSwitch.isOn, for: store)
        }
    }
}
