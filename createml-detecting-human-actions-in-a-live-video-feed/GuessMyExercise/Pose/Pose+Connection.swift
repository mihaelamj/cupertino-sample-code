/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `Connection` defines the line between two landmarks.
 The only real purpose for a connection is to draw that line with a gradient.
*/

import UIKit

extension Pose {
    /// Represents a line between two landmarks.
    struct Connection: Equatable {
        static let width: CGFloat = 12.0

        /// The gradient colors the connection uses to draw its line.
        static let colors = [UIColor.systemGreen.cgColor,
                             UIColor.systemYellow.cgColor,
                             UIColor.systemOrange.cgColor,
                             UIColor.systemRed.cgColor,
                             UIColor.systemPurple.cgColor,
                             UIColor.systemBlue.cgColor
        ] as CFArray

        static let gradientColorSpace = CGColorSpace(name: CGColorSpace.sRGB)

        static let gradient = CGGradient(colorsSpace: gradientColorSpace,
                                         colors: colors,
                                         locations: [0, 0.2, 0.33, 0.5, 0.66, 0.8])!

        /// The connection's first endpoint.
        private let point1: CGPoint

        /// The connection's second endpoint.
        private let point2: CGPoint

        /// Creates a connection from two points.
        ///
        /// The order of the points isn't important.
        /// - Parameters:
        ///   - one: The location for one end of the connection.
        ///   - two: The location for the other end of the connection.
        init(_ one: CGPoint, _ two: CGPoint) { point1 = one; point2 = two }

        /// Draws a line from the connection's first endpoint to its other
        /// endpoint.
        /// - Parameters:
        ///   - context: The Core Graphics context to draw to.
        ///   - transform: An affine transform that scales and translate each
        ///   endpoint.
        ///   - scale: The scale that adjusts the line's thickness
        func drawToContext(_ context: CGContext,
                           applying transform: CGAffineTransform? = nil,
                           at scale: CGFloat = 1.0) {

            let start = point1.applying(transform ?? .identity)
            let end = point2.applying(transform ?? .identity)

            // Store the current graphics state.
            context.saveGState()

            // Restore the graphics state after the method finishes.
            defer { context.restoreGState() }

            // Set the line's thickness.
            context.setLineWidth(Connection.width * scale)

            // Draw the line.
            context.move(to: start)
            context.addLine(to: end)
            context.replacePathWithStrokedPath()
            context.clip()
            context.drawLinearGradient(Connection.gradient,
                                       start: start,
                                       end: end,
                                       options: .drawsAfterEndLocation)
        }
    }
}

extension Pose {
    /// A series of joint pairs that define the wireframe lines of a pose.
    static let jointPairs: [(joint1: JointName, joint2: JointName)] = [
        // The left arm's connections.
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),

        // The left leg's connections.
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),

        // The right arm's connections.
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),

        // The right leg's connections.
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),

        // The torso's connections.
        (.leftShoulder, .neck),
        (.rightShoulder, .neck),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip)
    ]
}
