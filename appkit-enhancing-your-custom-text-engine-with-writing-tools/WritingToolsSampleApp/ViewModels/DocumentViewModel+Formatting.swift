/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Format handling for the custom text document editor view model.
*/

import Cocoa

// MARK: - Font Formatting
extension DocumentViewModel {
    func setFontWeight(_ weight: NSFont.Weight) {
        selectedTextFontWeight = weight
        guard firstSelection != nil,
              let range = firstSelectedRange else {
            return
        }
        
        guard let textStorage = textContentStorage.textStorage else {
            print("No text storage")
            return
        }
                
        textContentStorage.performEditingTransaction {
            textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: selectedTextFontWeight), range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        }
        viewModelDelegate?.textDidChange()
    }
    
    func updateFontAttributesForSelection() {
        var foundBold = false
        defer {
            if foundBold {
                selectedTextFontWeight = .bold
            } else {
                selectedTextFontWeight = .regular
            }
        }
        
        guard let selection = firstSelection,
              let range = firstRangeFromSelection(selection),
              range.location < allText.length - 1 else {
            return
        }
        
        if range.length == 0 {
            let attributes = allText.attributes(at: range.location, effectiveRange: nil)
            if let fontAttribute = attributes[.font] {
                if let font = fontAttribute as? NSFont {
                    foundBold = isBoldFont(font)
                }
            }
        } else {
            allText.enumerateAttribute(.font, in: range) { value, range, stop in
                if let font = value as? NSFont {
                    foundBold = isBoldFont(font)
                }
            }
        }
    }
    
    func isBoldFont(_ font: NSFont) -> Bool {
        return font.fontDescriptor.symbolicTraits.contains(NSFontDescriptor.SymbolicTraits.bold)
    }
}
