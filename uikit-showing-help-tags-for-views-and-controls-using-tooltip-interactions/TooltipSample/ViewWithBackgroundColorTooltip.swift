/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tooltip interaction delegate that displays the name of the view's background color.
*/

import UIKit

/// - Tag: ViewWithBackgroundColorTooltip
class ViewWithBackgroundColorTooltip: UIView, UIToolTipInteractionDelegate {
    
    func toolTipInteraction(_ interaction: UIToolTipInteraction, configurationAt point: CGPoint) -> UIToolTipConfiguration? {

        let configuration: UIToolTipConfiguration?
        if let accessibilityName = backgroundColor?.accessibilityName {
            configuration = UIToolTipConfiguration(toolTip: "The color is \(accessibilityName).")
        } else {
            configuration = nil
        }
        
        return configuration
    }

}
