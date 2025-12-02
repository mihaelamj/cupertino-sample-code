/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that behaves like a label by implementing the NSAccessibilityStaticText protocol.
*/

import Cocoa

class CustomTextLayer: CATextLayer, NSAccessibilityStaticText {

    var parent: NSView!
    
    // MARK: NSAccessibilityStaticText
    
    func accessibilityFrame() -> NSRect {
        return NSAccessibility.screenRect(fromView: parent, rect: frame)
    }
    
    func accessibilityParent() -> Any? {
        return NSAccessibility.unignoredAncestor(of: parent as Any)
    }
    
    func accessibilityValue() -> String? {
        return string as? String
    }
}

