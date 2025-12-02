/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Input handling for the custom text document editor view model.
*/

import Cocoa

// MARK: - Caret and navigation handling
extension DocumentViewModel {
    func moveCaret(direction: NSTextSelectionNavigation.Direction, destination: NSTextSelectionNavigation.Destination, extending: Bool = false) {
        let navigator = textLayoutManager.textSelectionNavigation
        guard let currentCaret = firstSelection,
            let dest = navigator.destinationSelection(
                for: currentCaret, direction: direction, destination: destination, extending: extending, confined: false) else {
            print("Having troubles figuring out where to navigate the caret to")
            return
        }
        setCaretPosition(dest)
    }

    @objc
    func inputDown(atPoint point: CGPoint) {
        let nav = textLayoutManager.textSelectionNavigation
        textLayoutManager.textSelections = nav.textSelections(interactingAt: point,
                                                               inContainerAt: textLayoutManager.documentRange.location,
                                                               anchors: [],
                                                               modifiers: [],
                                                               selecting: true,
                                                               bounds: .zero)
        
        updateFontAttributesForSelection()
        
        viewModelDelegate?.selectionDidChange()
    }
    
    @objc
    func inputMoved(atPoint point: CGPoint) {
        let nav = textLayoutManager.textSelectionNavigation
        
        textLayoutManager.textSelections = nav.textSelections(interactingAt: point,
                                                               inContainerAt: textLayoutManager.documentRange.location,
                                                               anchors: textLayoutManager.textSelections,
                                                               modifiers: .extend,
                                                               selecting: true,
                                                               bounds: .zero)
        
        updateFontAttributesForSelection()
        
        viewModelDelegate?.selectionDidChange()
    }
}
