/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the text field for the meme generator.
*/

import Cocoa

/// Self-centering text field
class TextField: NSTextField {
    
    struct DrawingItem {
        let text: String
        let font: NSFont
        let color: NSColor
        let origin: CGPoint
        
        func draw() {
            let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
            text.draw(at: origin, withAttributes: attributes)
        }
    }

    var isSelected: Bool = false {
        didSet {
            layer?.borderColor = isSelected ? NSColor.unemphasizedSelectedContentBackgroundColor.cgColor : nil
            layer?.borderWidth = isSelected ? 1.0 : 0.0
        }
    }
    
    private let defaultFont = NSFont.boldSystemFont(ofSize: 36)
    private let defaultTextColor = NSColor.white
    
    var drawingItem: DrawingItem {
        let itemFont = font ?? defaultFont
        let itemColor = textColor ?? defaultTextColor
        var origin = frame.origin
        origin.x += horizontalPadding * 0.5
        return DrawingItem(text: stringValue, font: itemFont, color: itemColor, origin: origin)
    }
    
    private let horizontalPadding: CGFloat = 16.0
    
    required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: horizontalPadding, height: 44))
        font = defaultFont
        alignment = .center
        textColor = defaultTextColor
        backgroundColor = .clear
        drawsBackground = false
        isBordered = false
        autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Centers the view if it has a superview.
    func centerInSuperview() {
        if let superview = superview {
            var centeredFrame = frame
            centeredFrame.origin.x = 0.5 * (superview.bounds.width - centeredFrame.width)
            centeredFrame.origin.y = 0.5 * (superview.bounds.height - centeredFrame.height)
            frame = backingAlignedRect(centeredFrame, options: .alignAllEdgesNearest)
        }
    }
    
    /// Changes the width keeping the center point fixed.
    func setFrameWidth(width: CGFloat) {
        frame = backingAlignedRect(frame.insetBy(dx: (frame.width - width) * 0.5, dy: 0.0), options: .alignAllEdgesNearest)
    }
    
    @discardableResult
    func makeFirstResponder() -> Bool {
        return window?.makeFirstResponder(self) ?? false
    }

    // MARK: - NSTextField
    
    override func textDidChange(_ notification: Notification) {
        if let editor = window?.fieldEditor(false, for: self) as? NSTextView,
            let newWidth = editor.textStorage?.size().width {
            setFrameWidth(width: ceil(newWidth) + horizontalPadding)
        }
    }
}
