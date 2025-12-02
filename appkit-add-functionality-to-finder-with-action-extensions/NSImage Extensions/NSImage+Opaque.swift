/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to NSImage that replaces a transparent background with a specific color.
*/

import Cocoa

extension NSImage {

    public func opaqueImage(backgroundColor: NSColor) -> NSImage {
        return NSImage(size: size, flipped: false, drawingHandler: { [unowned self] (rect) -> Bool in
            backgroundColor.setFill()
            let backgroundBounds = NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            let backgroundRect = NSBezierPath(rect: backgroundBounds)
            backgroundRect.fill()
            self.draw(in: rect)
            return true
        })
    }

}
