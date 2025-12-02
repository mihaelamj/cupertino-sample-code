/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tooltip interaction delegate that that displays a tooltip when the pointer hovers at the top or bottom area of the view.
*/

import UIKit

/// - Tag: ViewWithTooltipRegion
class ViewWithTooltipRegion: UIView, UIToolTipInteractionDelegate {

    func toolTipInteraction(_ interaction: UIToolTipInteraction, configurationAt point: CGPoint) -> UIToolTipConfiguration? {
        
        var topRect = self.bounds
        var bottomRect = self.bounds
        
        let partHeight = self.bounds.size.height / 3
        topRect.size.height = partHeight
        bottomRect.size.height = partHeight
        bottomRect.origin.y = partHeight * 2
        
        // Display the tooltip if the pointer within the top or bottom rects.
        if topRect.contains(point) {
            return UIToolTipConfiguration(toolTip: "Top area of the view.", in: topRect)
        } else if bottomRect.contains(point) {
            return UIToolTipConfiguration(toolTip: "Bottom area of the view.", in: bottomRect)
        }
        
        // Pointer is in the middle of the view; don't display a tooltip.
        return nil
    }
    
}
