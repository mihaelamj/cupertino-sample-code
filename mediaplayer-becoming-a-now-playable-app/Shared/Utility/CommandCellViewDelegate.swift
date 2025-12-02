/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`CommandCellViewDelegate` is used by a `CommandCellView` object to redirect actions to a view controller object.
*/

import Foundation

protocol CommandCellViewDelegate: AnyObject {
    
    // Invoked when the cell's "command disabled" checkbox is toggled.
    
    func updateCommandDisabledState(_ configPath: ConfigPath, disabled: Bool)
    
    // Invoked when the cell's "command registered" checkbox is toggled.
    
    func updateCommandRegisteredState(_ configPath: ConfigPath, registered: Bool)

}
