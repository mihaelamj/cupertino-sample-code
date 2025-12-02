/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for showing details of a store and viewing/editing its favorite status.
*/

import Cocoa

class StoreDetailViewController: NSViewController {

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
    
    @IBOutlet weak var storeNameLabel: NSTextField!
    @IBOutlet weak var favoriteButton: NSButton!
    @IBOutlet weak var addressLabel: NSTextField!
    
    private func updateUI() {
        DispatchQueue.main.async {
            if let store = self.store {
                self.storeNameLabel?.stringValue = store.name
                guard let address = store.placemark.postalAddress else {
                    self.addressLabel?.stringValue = ""
                    return
                }
                self.addressLabel?.stringValue = "\(address.subLocality) \(address.street)\n\(address.city), \(address.state)\n\(address.country)"
                if let storeDirectory = self.storeDirectory {
                    self.favoriteButton?.state = storeDirectory.isFavorite(store: store) ? .on : .off
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    @IBAction func handleFavoriteButtonClicked(_ sender: Any) {
        if let store = store, let storeDirectory = storeDirectory,
            let buttonState = self.favoriteButton?.state {
            storeDirectory.setFavorite(buttonState == .on ? true : false, for: store)
        }
    }
}
