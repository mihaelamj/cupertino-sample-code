/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Logic to render the selection highlight in a view.
*/

import Cocoa

class TextSelectionView: NSView {
    override var isFlipped: Bool { return true }
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    }
    
    func clearSelectionsAndCaret() {
        layer?.sublayers = nil
    }
    
    func drawSelection(frame: CGRect) {
        assert(frame.size.width > 0, "Cannot highlight zero width rect")
        let highlight = CALayer()
        highlight.backgroundColor = NSColor.selectedTextBackgroundColor.cgColor
        highlight.frame = frame
        layer?.addSublayer(highlight)
    }
    
    func drawCaret(frame: CGRect) {
        assert(frame.size.width == 0, "Frame given is not a caret")
        var caretFrame = frame
        let caret = CALayer()
        caretFrame.size.width = 2 // Thicken the caret.
        caret.backgroundColor = NSColor.textInsertionPointColor.cgColor
        caret.frame = caretFrame
        layer?.addSublayer(caret)
    }
}
