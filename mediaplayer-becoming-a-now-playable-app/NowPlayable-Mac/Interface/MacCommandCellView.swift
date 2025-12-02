/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`MacCommandCellView` is a cell that responds to the user enabling or disabling remote commands.
*/

import Cocoa

class MacCommandCellView: NSTableCellView {
    
    @IBOutlet weak var commandNameLabel: NSTextField!
    @IBOutlet weak var disabledButton: NSButton!
    @IBOutlet weak var registeredButton: NSButton!

    // The corresponding model index path.
    
    var configPath: ConfigPath!
    
    // The delegate that is used to respond to cell actions.
    
    weak var delegate: CommandCellViewDelegate?
    
    // Action methods for the controls in the cell.
    
    @IBAction func userDidToggleDisabledButton(_ sender: Any?) {
        delegate?.updateCommandDisabledState(configPath, disabled: disabledButton.state == .on)
    }
    
    @IBAction func userDidToggleRegisteredButton(_ sender: Any?) {
        delegate?.updateCommandRegisteredState(configPath, registered: registeredButton.state == .on)
    }

}

