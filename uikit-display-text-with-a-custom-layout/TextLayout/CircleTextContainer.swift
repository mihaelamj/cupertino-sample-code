/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The text container class that implements a circular text container.
*/

import UIKit

class CircleTextContainer: NSTextContainer {
    override func lineFragmentRect(forProposedRect proposedRect: CGRect,
                                   at characterIndex: Int,
                                   writingDirection baseWritingDirection: NSWritingDirection,
                                   remaining remainingRect: UnsafeMutablePointer<CGRect>?) -> CGRect {
        let rect = super.lineFragmentRect(forProposedRect: proposedRect,
                                          at: characterIndex,
                                          writingDirection: baseWritingDirection,
                                          remaining: remainingRect)
        let containerWidth = Float(size.width), containerHeight = Float(size.height)

        let diameter = fminf(containerWidth, containerHeight)
        let radius = diameter / 2.0
        
        // Vertical distance from the line center to the container center.
        let yDistance = fabsf(Float(rect.origin.y + rect.size.height / 2.0) - radius)
        // The new line width.
        let width = (yDistance < radius) ? 2.0 * sqrt(radius * radius - yDistance * yDistance) : 0.0
        // Horizontal distance from rect.origin.x to the starting point of the line.
        let xOffset = (containerWidth > diameter) ? (containerWidth - diameter) / 2.0 : 0.0
        // The starting x of the line.
        let xPosition = CGFloat(xOffset + Float(rect.origin.x) + radius - width / 2.0)
        return CGRect(x: xPosition, y: CGFloat(rect.origin.y), width: CGFloat(width), height: rect.size.height)
    }
}
