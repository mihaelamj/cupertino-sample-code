/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tooltip interaction delegate that displays the tooltip when the pointer hovers over selected text in the text view.
*/

import UIKit

/// - Tag: TextViewWithTooltip
class TextViewWithTooltip: UITextView, UIToolTipInteractionDelegate {
    
    func toolTipInteraction(_ interaction: UIToolTipInteraction, configurationAt point: CGPoint) -> UIToolTipConfiguration? {
        
        guard
            let selectedTextRange = self.selectedTextRange,
            selectedTextRange.isEmpty == false
        else {
            return nil
        }

        var unionedRect = firstRect(for: selectedTextRange)
        for selectionRect in selectionRects(for: selectedTextRange) {
            unionedRect = unionedRect.union(selectionRect.rect)
        }
        
        if let selectedText = text(in: selectedTextRange) {
            return UIToolTipConfiguration(toolTip: "Selected text: \(selectedText)", in: unionedRect)
        }
        
        return nil
    }
    
}
