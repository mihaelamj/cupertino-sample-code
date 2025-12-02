/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that draws text using
 CoreText by implementing the NSAccessibilityStaticText protocol.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom control.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit:
 https://developer.apple.com/documentation/appkit/nscontrol
*/

class CoreTextView: NSView {

    var font = NSFont(name: "Didot", size: 48.0)
    var string = NSLocalizedString("Hello World", comment: "Hello world")
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Drawing

    fileprivate func drawText(context: CGContext, text: String, attributes: [NSAttributedString.Key: AnyObject], xLoc: CGFloat, yLoc: CGFloat) {
        let font = attributes[NSAttributedString.Key.font]
        let attributedString = NSAttributedString(string: text as String, attributes: attributes)
        let textSize = text.size(withAttributes: attributes)
        let textPath = CGPath(rect: CGRect(x: xLoc, y: yLoc + (font?.descender)!, width: ceil(textSize.width), height: ceil(textSize.height)),
                              transform: nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedString.length), textPath, nil)
        
        CTFrameDraw(frame, context)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let cgContext = NSGraphicsContext.current?.cgContext
        
        // First draw the background.
        let path = CGMutablePath()
        path.addRect(dirtyRect)
        cgContext?.addPath(path)
        NSColor.white.setFill()
        cgContext?.drawPath(using: .fillStroke)
        
        // Draw out CoreText string.
        let attrStr = accessibilityAttributedString(for: NSRange(location: 0, length: string.count))
        var range = CFRange(location: 0, length: CFAttributedStringGetLength(attrStr)) as CFRange
        if let attributes = CFAttributedStringGetAttributes(attrStr, 0, &range) as? [NSAttributedString.Key: AnyObject] {
            drawText(context: cgContext!, text: (attrStr?.string)!, attributes: attributes, xLoc: 70, yLoc: 54)
        }
    }
    
}

// MARK: - NSAccessibilityStaticText

extension CoreTextView {
    
    override func accessibilityValue() -> Any? {
        return string
    }
    
    override func accessibilityVisibleCharacterRange() -> NSRange {
        return NSRange(location: 0, length: string.count)
    }
    
    override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? {
        let attributes = [NSAttributedString.Key.font: font!, NSAttributedString.Key.ligature: NSNumber(value: 0)] as [NSAttributedString.Key: Any]
        let attrString = NSAttributedString(string: string, attributes: attributes)
        return attrString
    }
    
}
