/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`IOSEnabledItemCell` is a cell that responds to the user enabling or disabling a configuration item.
*/

import UIKit

class IOSEnabledItemCell: UITableViewCell {
    
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var enabledButton: UISwitch!
    
    // The corresponding model index path.
    
    var configPath: ConfigPath!
    
    // The delegate that is used to respond to cell actions.
    
    weak var delegate: EnabledItemCellViewDelegate?
    
    // Action method for the controls in the cell.
    
    @IBAction func userDidToggleEnabledButton(_ sender: Any?) {
        delegate?.updateEnabledItemState(configPath, enabled: enabledButton.isOn)
    }
    
}
