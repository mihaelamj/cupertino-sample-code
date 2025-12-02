/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A single cell of the collection view that displays a single accessory.
*/

import UIKit
import HomeKit

class AccessoryCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var disclosureButton: UIButton!
    
    /// The service that this cell represents.
    var service: HMService? {
        didSet {
            imageView.image = service?.icon
            
            roomLabel.text = service?.accessory?.room?.name
            nameLabel.text = service?.name
            stateLabel.text = "Updating..."

            readAndRedraw(characteristic: service?.primaryDisplayCharacteristic, animated: true)
        }
    }
    
    /// Reads the characteristic value from the HomeKit database, and updates the UI.
    func readAndRedraw(characteristic: HMCharacteristic?, animated: Bool) {
        guard
            let characteristic = characteristic,
            characteristic.properties.contains(HMCharacteristicPropertyReadable),
            let accessory = characteristic.service?.accessory,
            accessory.isReachable else {
                stateLabel.text = "Unreachable"
                return
        }
        
        characteristic.readValue { error in
            self.redrawState(error: error)
        }
    }
    
    /// Updates the UI to reflect the given state.
    func redrawState(error: Error? = nil) {
        imageView.image = service?.icon

        if let error = error {
            print(error.localizedDescription)
            stateLabel.text = "Update error!"
        } else {
            stateLabel.text = service?.state
        }
    }
    
    /// Informs the cell that it's been tapped.
    func tap() {
        if let characteristic = service?.primaryControlCharacteristic,
            let value = characteristic.value as? Bool {

            // Provide visual feedback that the item was tapped.
            bounce()
            
            // Write the new value to HomeKit.
            characteristic.writeValue(!value) { error in
                self.redrawState(error: error)
            }
        }
    }

    /// Animates the cell size in a way that looks like a little bounce.
    private func bounce() {
        UIView.animate(withDuration: 0.05, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) {_ in
            UIView.animate(withDuration: 0.10, animations: {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }) {_ in
                UIView.animate(withDuration: 0.15, animations: {
                    self.transform = .identity
                })
            }
        }
    }
}
