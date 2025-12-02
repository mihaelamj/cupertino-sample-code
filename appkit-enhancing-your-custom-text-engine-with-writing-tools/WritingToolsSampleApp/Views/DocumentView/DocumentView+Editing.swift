/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of text editing support for the Document View.
*/

import Cocoa

extension DocumentView {
    override func mouseDown(with event: NSEvent) {
        if inputContext?.handleEvent(event) ?? false {
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        viewModel.inputDown(atPoint: point)
    }
    
    override func mouseDragged(with event: NSEvent) {
        if inputContext?.handleEvent(event) ?? false {
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        viewModel.inputMoved(atPoint: point)
    }
    
    override func mouseUp(with event: NSEvent) {
        inputContext?.handleEvent(event)
    }
    
    override func keyDown(with event: NSEvent) {
        NSCursor.setHiddenUntilMouseMoves(true)
        if !(inputContext?.handleEvent(event) ?? false) {
            super.keyDown(with: event)
        }
    }
}

// MARK: - NSStandardKeyBindingResponding support
extension DocumentView {
    override func moveRight(_ sender: Any?) {
        viewModel.moveCaret(direction: .right, destination: .character)
    }

    override func moveLeft(_ sender: Any?) {
        viewModel.moveCaret(direction: .left, destination: .character)
    }

    override func moveUp(_ sender: Any?) {
        viewModel.moveCaret(direction: .up, destination: .character)
    }

    override func moveDown(_ sender: Any?) {
        viewModel.moveCaret(direction: .down, destination: .character)
    }

    override func moveToBeginningOfLine(_ sender: Any?) {
        viewModel.moveCaret(direction: .up, destination: .line)
    }

    override func moveToEndOfLine(_ sender: Any?) {
        viewModel.moveCaret(direction: .down, destination: .line)
    }

    override func moveToBeginningOfParagraph(_ sender: Any?) {
        viewModel.moveCaret(direction: .up, destination: .paragraph)
    }

    override func moveToEndOfParagraph(_ sender: Any?) {
        viewModel.moveCaret(direction: .down, destination: .paragraph)
    }

    override func moveToEndOfDocument(_ sender: Any?) {
        viewModel.moveCaret(direction: .down, destination: .document)
    }

    override func moveToBeginningOfDocument(_ sender: Any?) {
        viewModel.moveCaret(direction: .up, destination: .document)
    }
    
    override func moveRightAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .right, destination: .character, extending: true)
    }

    override func moveLeftAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .left, destination: .character, extending: true)
    }

    override func moveWordRightAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .right, destination: .word, extending: true)
    }

    override func moveWordLeftAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .left, destination: .word, extending: true)
    }
    
    override func moveUpAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .up, destination: .character, extending: true)
    }

    override func moveDownAndModifySelection(_ sender: Any?) {
        viewModel.moveCaret(direction: .down, destination: .character, extending: true)
    }

    override func deleteForward(_ sender: Any?) {
        performDelete(forward: true)
    }

    override func deleteBackward(_ sender: Any?) {
        performDelete(forward: false)
    }
    
    private func performDelete(forward: Bool) {
        guard let firstSelectionRange = viewModel.firstSelectedRange else {
            return
        }
        
        defer {
            inputContext?.invalidateCharacterCoordinates()
        }
        
        // If text is selected, delete the selection regardless of direction.
        if firstSelectionRange.length > 0 {
            viewModel.deleteSelectedText()
            return
        }
        
        // Calculate the range to delete based on the direction.
        var deleteRange = firstSelectionRange
        if forward {
            // Forward delete: check if there is anything to delete ahead.
            guard deleteRange.location < viewModel.allText.length else { return }
            deleteRange.length = 1
        } else {
            // Backward delete: check if there is anything to delete behind.
            guard deleteRange.location > 0 else { return }
            deleteRange.location -= 1
            deleteRange.length = 1
        }
        
        let emptyString = NSAttributedString(string: "")
        viewModel.replaceText(inRange: deleteRange, with: emptyString, applyingDefaultAttributes: false)
    }
    
    override func insertNewline(_ sender: Any?) {
        insertText("\n", replacementRange: NSRange(location: NSNotFound, length: 0))
    }
}

// MARK: - NSTextInputClient implementation
extension DocumentView: @preconcurrency NSTextInputClient {
    func insertText(_ string: Any, replacementRange: NSRange) {
        var selectedRange: NSRange?
        if replacementRange.location != NSNotFound {
            selectedRange = replacementRange
        } else {
            selectedRange = viewModel.markedTextRange ?? viewModel.firstSelectedRange
        }
        guard let selectedRange else {
            return
        }
        
        if let string = string as? NSAttributedString {
            viewModel.replaceText(inRange: selectedRange, with: string, applyingDefaultAttributes: true)
        } else if let string = string as? String {
            viewModel.replaceText(inRange: selectedRange, with: NSAttributedString(string: string), applyingDefaultAttributes: true)
        } else {
            fatalError("\(#function): The `string` argument has an unsupported type \(type(of: string))")
        }
        
        // Clear the marked text.
        unmarkText()
        inputContext?.invalidateCharacterCoordinates()
    }

    func selectedRange() -> NSRange {
        guard let currentSelection = viewModel.firstSelectedRange else {
            return NSRange(location: NSNotFound, length: 0)
        }
        
        return currentSelection
    }
        
    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        guard range.location != NSNotFound else {
            print("Range has no valid location")
            return nil
        }

        let allText = viewModel.allText
        if (range.length < 0) || (NSMaxRange(range) > allText.length) {
            return allText
        } else {
            return NSAttributedString(attributedString: allText.attributedSubstring(from: range))
        }
    }
    
    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        []
    }
    
    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        // The actualViewFrame is correct, the self.frame value changes depending on content size.
        guard let actualViewFrame = self.superview?.frame, let scrollView = enclosingScrollView else {
            print("Could not get superview frame or scrollview")
            return NSRect()
        }
        
        if range.location + range.length > viewModel.allText.length {
            print("Range requested is outside of viewModel text range")
            return NSRect()
        }
        var selectionRect = viewModel.unionSelectionRect(for: range)
        
        // Adjust for scroll position.
        selectionRect.origin.y -= scrollView.documentVisibleRect.origin.y
        
        // Adjust for the position in the window.
        selectionRect.origin.x += self.window!.frame.width - actualViewFrame.width
        selectionRect.origin.y += self.window!.frame.height - actualViewFrame.height
        
        // Flip along the Y-axis.
        selectionRect.origin.y = self.window!.frame.height - (selectionRect.origin.y + selectionRect.height)
        
        // Convert to the screen coordinates.
        var rectInScreen = self.window?.convertToScreen(selectionRect) ?? NSRect(x: 1, y: 1, width: 1, height: 1)
        
        // The origin cannot be (0,0). If you want to present character picker, put in a real value.
        if rectInScreen.origin.x == 0 && rectInScreen.origin.y == 0 {
            rectInScreen.origin = NSPoint(x: 1, y: 1)
        }
        
        return rectInScreen
    }
    
    func characterIndex(for point: NSPoint) -> Int {
        if let offset = viewModel.closestPosition(to: point) {
            return offset
        }
        
        return 0
    }

    // MARK: - Edit menu: Cut-Copy-Paste, Delete, and Select all support
    @IBAction func cut(_ sender: Any) {
        viewModel.cutToPasteBoard()
    }

    @IBAction func copy(_ sender: Any) {
        viewModel.copyToPasteBoard()
    }

    @IBAction func paste(_ sender: Any) {
        viewModel.pasteToDocument()
    }

    @IBAction func selectAll(_ sender: Any) {
        viewModel.selectAllDocumentText()
    }
    
    @IBAction func delete(_ sender: Any) {
        viewModel.deleteSelectedText()
    }
}

// MARK: - Marked text support
extension DocumentView {
    func hasMarkedText() -> Bool {
        let result = viewModel.markedTextRange != nil
        return result
    }
    
    func markedRange() -> NSRange {
        let result = viewModel.markedTextRange ?? NSRange(location: NSNotFound, length: 0)
        return result
    }
    
    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        // Grab the marked text from the string.
        // The type of `string` can be String or NSAttributedString.
        let markedText: NSAttributedString
        if let markedString = string as? String {
            markedText = NSAttributedString(string: markedString)
        } else if let markAttributedString = string as? NSAttributedString {
            markedText = markAttributedString
        } else {
            fatalError("\(#function): The `string` argument has an unsupported type \(type(of: string))")
        }
        
        var targetRange = replacementRange
        if replacementRange.location == NSNotFound {
            targetRange = viewModel.markedTextRange ?? self.selectedRange()
        }
        
        // Put the marked text to the current marked text range.
        guard let textStorage = viewModel.textContentStorage.textStorage else {
            fatalError("The view model doesn't have a text storage available.")
        }
        let markedTextLength = markedText.length
        viewModel.textContentStorage.performEditingTransaction {
            if markedTextLength == 0 {
                textStorage.deleteCharacters(in: targetRange)
                unmarkText()
            } else {
                viewModel.markedTextRange = NSRange(location: targetRange.location, length: markedText.length)
                viewModel.replaceText(inRange: targetRange, with: markedText, applyingDefaultAttributes: true)
            }
        }
        inputContext?.invalidateCharacterCoordinates()
    }
    
    func unmarkText() {
        viewModel.markedTextRange = nil
    }
}
