/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view cell that displays a label and toggle switch.
*/

import UIKit

typealias ValidDidChange = (Bool) -> Void

class OptionsCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var toggle: UISwitch!
    var valueDidChange: ValidDidChange? = nil
    
    override func prepareForReuse() {
        super.prepareForReuse()
        valueDidChange = nil
    }
    
    func configureWith(text: String, isOn: Bool, valueDidChange: ValidDidChange?) {
        label.text = text
        toggle.isOn = isOn
        self.valueDidChange = valueDidChange
    }
    
    @IBAction func didToggle(_ sender: UISwitch) {
        if let valueDidChange = self.valueDidChange {
            valueDidChange(sender.isOn)
        }
    }
}
