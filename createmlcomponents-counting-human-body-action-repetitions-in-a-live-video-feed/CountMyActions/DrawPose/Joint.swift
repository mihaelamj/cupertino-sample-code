/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The name and location of a point on a human body, such as the left shoulder, right eye, or nose.
*/

import SwiftUI
import CreateMLComponents

extension JointPoint {
    /// The minimum confidence for a valid `JointPoint`. The range is between 0 and 1.
    static let confidenceThreshold: Float = 0.2

    /// The drawing radius of a landmark.
    static let radius: CGFloat = 14.0

    /// Draws a circle at the joint landmark's location after transformation.
    /// - Parameters:
    ///   - context: A context the method uses to draw the landmark.
    ///   - transform: A transform that modifies the point locations.
    ///   - scale: The scale that adjusts the point's radius.
    func drawJoint(to context: GraphicsContext,
                   applying transform: CGAffineTransform = .identity,
                   at scale: CGFloat = 1.0) {

        // Define the rectangle's origin by applying the transform to the
        // joint landmark's normalized location.
        let origin = location.applying(transform)

        // Define the size of the circle's rectangle with the radius.
        let radius = JointPoint.radius * scale
        let diameter = radius * 2
        let rectangle = CGRect(x: origin.x - radius,
                               y: origin.y - radius,
                               width: diameter,
                               height: diameter)

        let ellipse = Path(ellipseIn: rectangle)

        context.fill(ellipse, with: .color(.white))
        context.stroke(ellipse, with: .color(.gray))
    }
    
}
