/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table cell that summarizes one characteristic.
*/

import UIKit
import HomeKit

class CharacteristicCell: UITableViewCell {
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var toggle: UISwitch!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    /// Writes to the characteristic as the user moves the slider back and forth.
    @IBAction func sliderDidChange(_ sender: UISlider) {
        guard let characteristic = characteristic else { return }
        
        // Convert to a value in range, and on the grid.
        let value = characteristic.valueFor(fraction: sender.value)
        
        // Only write when there’s a change.
        guard
            let oldValue = characteristic.decimalValue,
            value != oldValue else { return }
        
        // Write the new value.
        characteristic.writeValue(value) { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // Update the label to match.
                self.redrawValueLabel()
            }
        }
    }
    
    /// Ensures the final state of the UI matches reality after the user finishes sliding.
    @IBAction func sliderTouchUp(_ sender: Any) {
        readAndRedrawValue(animated: false)
    }
    
    /// Updates the characteristic value when the toggle switch changes state.
    @IBAction func toggleDidChange(_ sender: UISwitch) {
        guard let characteristic = characteristic else { return }
        
        characteristic.writeValue(sender.isOn) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Updates the characteristic value when the segmented control changes state.
    @IBAction func segDidChange(_ sender: UISegmentedControl) {
        guard let characteristic = characteristic else { return }
        
        characteristic.writeValue(sender.selectedSegmentIndex) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    /// The characteristic that this cell displays.
    var characteristic: HMCharacteristic? {
        
        // Update the UI when a new characteristic is set.
        didSet {
            // A cell with no characteristic shows as empty.
            guard
                let characteristic = characteristic,
                let accessory = characteristic.service?.accessory else {
                    nameLabel.text = nil
                    valueLabel.text = nil
                    slider.isHidden = true
                    toggle.isHidden = true
                    return
            }
            
            // Set the characteristic’s name
            nameLabel.text = characteristic.displayName
            
            // Show the toggle for reachable, writeable, Boolean characteristics.
            toggle.isHidden = !accessory.isReachable || !characteristic.isBool || !characteristic.isWriteable
            toggle.isOn = false
            
            // Show the segmented control for writeable values with declared state names.
            segmentedControl.isHidden = !(accessory.isReachable && characteristic.isWriteable && !characteristic.stateNames.isEmpty)
            if !segmentedControl.isHidden {
                segmentedControl.removeAllSegments()
                for index in 0...(characteristic.stateNames.count - 1) {
                    let name = characteristic.stateNames[index]
                    segmentedControl.insertSegment(withTitle: name, at: index, animated: false)
                }
            }
            
            // Show the slider for other numbers.
            slider.isHidden = !(segmentedControl.isHidden && accessory.isReachable && characteristic.isNumeric && characteristic.stateNames.isEmpty)
            slider.isEnabled = characteristic.isWriteable
            slider.value = 0
            
            // Value label shows when toggle and segment are hidden.
            valueLabel.isHidden = !(toggle.isHidden && segmentedControl.isHidden)
            valueLabel.text = "—"
            
            // Execute a read, and then update the UI with it.
            readAndRedrawValue(animated: false)
        }
    }
    
    /// Reads the characteristic value from the HomeKit database, and updates the UI.
    func readAndRedrawValue(animated: Bool) {
        guard
            let characteristic = characteristic,
            characteristic.isReadable,
            let accessory = characteristic.service?.accessory,
            accessory.isReachable else { return }
        
        characteristic.readValue { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.redrawValueLabel()
                self.redrawControls(animated: animated)
            }
        }
    }
    
    /// Sets the cell’s secondary text according to the current characteristic value.
    func redrawValueLabel() {
        valueLabel.text = characteristic?.formattedValueString
    }
    
    /// Sets any visible graphical control to the current characteristic value.
    func redrawControls(animated: Bool) {
        guard
            let characteristic = characteristic,
            let value = characteristic.value else { return }
        
        if !slider.isHidden {
            if let decimalValue = characteristic.decimalValue {
                let fraction = (decimalValue / characteristic.span) as NSNumber
                slider.setValue(fraction.floatValue, animated: animated)
            }
            
        } else if !toggle.isHidden {
            if let boolValue = value as? Bool {
                toggle.setOn(boolValue, animated: animated)
            }
            
        } else if !segmentedControl.isHidden {
            if let intValue = value as? Int {
                segmentedControl.selectedSegmentIndex = intValue
            }
        }
    }
}
