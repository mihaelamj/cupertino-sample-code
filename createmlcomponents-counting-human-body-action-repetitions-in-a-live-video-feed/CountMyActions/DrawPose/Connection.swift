/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Draws a line with a gradient to define the line between two joint landmarks.
*/

import SwiftUI
import CreateMLComponents

extension Pose {
    /// Represents a line between two joints.
    struct Connection: Equatable {
        static let width: CGFloat = 12.0

        /// The gradient colors that the connection uses to draw its line.
        let colors: [Color] = [
            .green,
            .yellow,
            .orange,
            .red,
            .purple,
            .blue
        ]

        /// The connection's first endpoint.
        private let point1: CGPoint

        /// The connection's second endpoint.
        private let point2: CGPoint

        /// Creates a connection from two points.
        ///
        /// The order of the points isn't important.
        /// - Parameters:
        ///   - point1: The location for one end of the connection.
        ///   - point2: The location for the other end of the connection.
        init(_ point1: CGPoint, _ point2: CGPoint) {
            self.point1 = point1
            self.point2 = point2
        }

        /// Draws a line from the connection's first endpoint to its other
        /// endpoint.
        /// - Parameters:
        ///   - context: A context the method uses to draw the connection.
        ///   - transform: An affine transform that scales and translates each
        ///   endpoint.
        ///   - scale: The scale that adjusts the line's thickness.
        func drawConnection(to context: GraphicsContext,
                            applying transform: CGAffineTransform = .identity,
                            at scale: CGFloat = 1.0) {

            let start = point1.applying(transform)
            let end = point2.applying(transform)

            let path = Path { newPath in
                newPath.move(to: start)
                newPath.addLine(to: end)
            }

            let gradient = Gradient(colors: colors)

            let shading: GraphicsContext.Shading =
                .linearGradient(gradient, startPoint: start, endPoint: end)

            context.stroke(path,
                           with: shading,
                           lineWidth: Connection.width * scale
            )
        }
    }

    /// Creates an array of connections from the available joint landmarks.
    func buildConnections() -> [Connection] {
        var connections = [Connection]()

        // Add a connection if both of its endpoints have valid joints.
        for jointPair in Pose.jointPairs {
            // A joint is valid only when its confidence is above the confidence threshold.
            guard let point1 = keypoints[jointPair.joint1],
                    point1.confidence >= JointPoint.confidenceThreshold else { continue }
            guard let point2 = keypoints[jointPair.joint2],
                    point2.confidence >= JointPoint.confidenceThreshold else { continue }

            connections.append(Connection(point1.location, point2.location))
        }
        return connections
    }
}

extension Pose {
    /// A series of joint pairs that define the wireframe lines of a pose.
    static let jointPairs: [(joint1: JointKey, joint2: JointKey)] = [
        // The left arm's connections.
        (.leftShoulder, .leftElbow),
        (.leftWrist, .leftElbow),

        // The left leg's connections.
        (.leftHip, .leftKnee),
        (.leftAnkle, .leftKnee),

        // The right arm's connections.
        (.rightShoulder, .rightElbow),
        (.rightWrist, .rightElbow),

        // The right leg's connections.
        (.rightHip, .rightKnee),
        (.rightAnkle, .rightKnee),

        // The torso's connections.
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip)
    ]
}
