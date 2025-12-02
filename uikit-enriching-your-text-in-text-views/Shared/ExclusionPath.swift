/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility that hosts the exclusion paths.
*/

import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// Generate a bezier path for the image.
struct ExclusionPath {
#if os(iOS)
    static var uiBezierPath: UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 24.5, y: 59.5))
        bezierPath.addCurve(to: CGPoint(x: -1.5, y: 154.5), controlPoint1: CGPoint(x: -9.24, y: 101.69), controlPoint2: CGPoint(x: -1.5, y: 154.5))
        bezierPath.addLine(to: CGPoint(x: 111.5, y: 154.5))
        bezierPath.addLine(to: CGPoint(x: 139.5, y: 183.5))
        bezierPath.addLine(to: CGPoint(x: 236.5, y: 88.5))
        bezierPath.addLine(to: CGPoint(x: 259.5, y: 110.5))
        bezierPath.addLine(to: CGPoint(x: 298.5, y: 75.5))
        bezierPath.addCurve(to: CGPoint(x: 244.5, y: 19.5), controlPoint1: CGPoint(x: 298.5, y: 75.5), controlPoint2: CGPoint(x: 255.5, y: 30.5))
        bezierPath.addCurve(to: CGPoint(x: 161.5, y: 14.5), controlPoint1: CGPoint(x: 237.74, y: 12.74), controlPoint2: CGPoint(x: 215.5, y: -4.5))
        bezierPath.addCurve(to: CGPoint(x: 111.5, y: 14.5), controlPoint1: CGPoint(x: 161.5, y: 14.5), controlPoint2: CGPoint(x: 119.21, y: 14.5))
        bezierPath.addCurve(to: CGPoint(x: 24.5, y: 59.5), controlPoint1: CGPoint(x: 76.19, y: 14.86), controlPoint2: CGPoint(x: 43.21, y: 36.11))
        bezierPath.close()
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 45, y: 30)
        bezierPath.apply(transform)
        return bezierPath
    }
#else
    static var nsBezierPath: NSBezierPath {
        let bezierPath = NSBezierPath()
        bezierPath.move(to: NSPoint(x: 25.5, y: 58.5))
        bezierPath.curve(to: NSPoint(x: -0.5, y: 153.5), controlPoint1: NSPoint(x: -8.24, y: 100.69), controlPoint2: NSPoint(x: -0.5, y: 153.5))
        bezierPath.line(to: NSPoint(x: 112.5, y: 153.5))
        bezierPath.line(to: NSPoint(x: 140.5, y: 182.5))
        bezierPath.line(to: NSPoint(x: 237.5, y: 87.5))
        bezierPath.line(to: NSPoint(x: 260.5, y: 109.5))
        bezierPath.line(to: NSPoint(x: 299.5, y: 74.5))
        bezierPath.curve(to: NSPoint(x: 245.5, y: 18.5), controlPoint1: NSPoint(x: 299.5, y: 74.5), controlPoint2: NSPoint(x: 256.5, y: 29.5))
        bezierPath.curve(to: NSPoint(x: 165.5, y: 23.5), controlPoint1: NSPoint(x: 234.5, y: 7.5), controlPoint2: NSPoint(x: 188.5, y: -6.5))
        bezierPath.curve(to: NSPoint(x: 112.5, y: 13.5), controlPoint1: NSPoint(x: 154.5, y: 15), controlPoint2: NSPoint(x: 132.5, y: 13.5))
        bezierPath.curve(to: NSPoint(x: 25.5, y: 58.5), controlPoint1: NSPoint(x: 77.19, y: 13.86), controlPoint2: NSPoint(x: 44.21, y: 35.11))
        bezierPath.close()
        var transform = AffineTransform.identity
        transform.translate(x: 45, y: 65)
        bezierPath.transform(using: transform)
        return bezierPath
    }
#endif
}
