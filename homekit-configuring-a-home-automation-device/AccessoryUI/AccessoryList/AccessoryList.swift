/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of known Kilgo accessories in the home.
*/

import UIKit
import HomeKit

/// - Tag: AccessoryList
class AccessoryList: UICollectionViewController {
    
    /// The filtered list of services that the app displays.
    var kilgoServices = [HMService]()    // These are called "accessories" in the UI.

    /// The home whose accessories the app displays.
    var home: HMHome? {
        didSet {
            home?.delegate = HomeStore.shared
            reloadData()
        }
    }
    
    /// Resets the list of Kilgo services from the currently set home.
    func reloadData() {
        kilgoServices = []

        guard let home = home else { return }

        for accessory in home.accessories.filter({ $0.manufacturer == "Kilgo Devices, Inc." }) {
            accessory.delegate = HomeStore.shared
            
            for service in accessory.services.filter({ $0.isUserInteractive }) {
                kilgoServices.append(service)
                
                // Ask for notifications from any characteristics that support them.
                for characteristic in service.characteristics.filter({
                    $0.properties.contains(HMCharacteristicPropertySupportsEventNotification)
                }) {
                    characteristic.enableNotification(true) { _ in }
                }
            }
        }

        collectionView.reloadData()
    }
    
    /// Registers this view controller to receive various delegate callbacks.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HomeStore.shared.homeManager.delegate = self
        HomeStore.shared.addHomeDelegate(self)
        HomeStore.shared.addAccessoryDelegate(self)
    }
    
    /// Deregisters this view controller as various kinds of delegate.
    deinit {
        HomeStore.shared.homeManager.delegate = nil
        HomeStore.shared.removeHomeDelegate(self)
        HomeStore.shared.removeAccessoryDelegate(self)
    }

    /// Prepares to show the detail view for an accessory.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
            let accessoryDetail = segue.destination as? AccessoryDetail,
            let button = sender as? UIButton {

            accessoryDetail.service = kilgoServices[button.tag]
            accessoryDetail.home = home
        }
    }
    
    /// Starts the add accessory flow.
    @IBAction func tapAdd(_ sender: UIBarButtonItem) {
        home?.addAndSetupAccessories(completionHandler: { error in
            if let error = error {
                print(error)
            } else {
                // Make no assumption about changes; just reload everything.
                self.reloadData()
            }
        })
    }

    // MARK: UICollectionViewDataSource

    /// Tells the collection view to create one cell for each service.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kilgoServices.count
    }

    /// Supplies the collection view with configured cells.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccessoryCell", for: indexPath)
        cell.layer.cornerRadius = 10

        if let accessoryCell = cell as? AccessoryCell {
            accessoryCell.service = kilgoServices[indexPath.item]
            accessoryCell.disclosureButton.tag = indexPath.item
        }

        return cell
    }

    /// Passes taps along to the cell.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? AccessoryCell)?.tap()
    }
}
