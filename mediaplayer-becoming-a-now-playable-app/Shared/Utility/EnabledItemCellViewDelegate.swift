/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`EnabledItemCellViewDelegate` is used by a `EnabledItemCellView` object to redirect actions to a view controller object.
*/

import Foundation

protocol EnabledItemCellViewDelegate: AnyObject {
    
    // Invoked when the cell's "enabled" checkbox is toggled.
    
    func updateEnabledItemState(_ configPath: ConfigPath, enabled: Bool)
    
}
