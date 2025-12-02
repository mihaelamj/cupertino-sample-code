/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Core logic and operations for the custom text document editor view model.
*/

import Cocoa

class DocumentViewModel: NSObject {
    let textContentStorage = NSTextContentStorage()
    let textLayoutManager = NSTextLayoutManager()
    weak var viewModelDelegate: ViewModelDelegate?
    
    var markedTextRange: NSRange?
    var selectedTextFontWeight: NSFont.Weight = .regular
    
    var allText: NSAttributedString {
        NSAttributedString(attributedString: (textContentStorage.attributedString ?? NSAttributedString()))
    }
    
    var currentSelections: [NSTextSelection] {
        return textLayoutManager.textSelections
    }
    
    var firstSelection: NSTextSelection? {
        return currentSelections.first
    }
    
    var firstSelectedRange: NSRange? {
        if let textRange = firstSelection?.textRanges.first {
            return range(forTextRange: textRange)
        }
        return nil
    }
    
    var selectedAttributedStrings: [NSAttributedString] {
        var ret: [NSAttributedString] = []
        guard let attributedString = textContentStorage.attributedString else {
            return ret
        }
        
        for selection in currentSelections {
            for range in rangesFromSelection(selection) {
                ret.append(attributedString.attributedSubstring(from: range))
            }
        }
        return ret
    }

    var firstSelectedAttributedString: NSAttributedString {
        // Returns the *first* range selected. This is sufficient in
        // certain circumstances, but not sufficient in many cases.
        // For example, one visual selection of bi-directional text can
        // contain two or more ranges.

        return selectedAttributedStrings.first ?? NSAttributedString(string: "")
    }
    
    override init() {
        super.init()
        
        textContentStorage.addTextLayoutManager(textLayoutManager)
        
        let textContainer = NSTextContainer(size: .zero)
        textLayoutManager.textContainer = textContainer
    }
}

protocol ViewModelDelegate: AnyObject {
    func textDidChange()
    func selectionDidChange()
}

// MARK: - Primitive operations to text storage
extension DocumentViewModel {
    @objc
    func replaceText(inRange range: NSRange, with text: NSAttributedString) {
        guard let textStorage = textContentStorage.textStorage else {
            print("No text storage")
            return
        }
                
        textContentStorage.performEditingTransaction {
            textStorage.replaceCharacters(in: range, with: text)
        }

        viewModelDelegate?.textDidChange()
    }
    
    func replaceText(inRange range: NSRange, with text: NSAttributedString, applyingDefaultAttributes applyAttributes: Bool) {
        let mutableAttributedString = NSMutableAttributedString(attributedString: text)
        if applyAttributes {
            mutableAttributedString.addAttributes([
                .foregroundColor: NSColor.textColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ], range: NSRange(location: 0, length: mutableAttributedString.length))
            replaceText(inRange: range, with: mutableAttributedString)
        } else {
            replaceText(inRange: range, with: text)
        }
    }
    
    func clearText() {
        replaceText(inRange: .init(location: 0, length: textContentStorage.textStorage?.length ?? 0), with: NSAttributedString())
        viewModelDelegate?.textDidChange()
    }
}
