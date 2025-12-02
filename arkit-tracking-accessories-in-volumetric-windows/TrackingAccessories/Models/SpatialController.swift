/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a spatial controller and its associated actions.
*/

import ARKit

@Observable
@MainActor
final class SpatialController {
    var anchor: AccessoryAnchor? = nil
    
    /// Returns `true` if the controller is connected and you're tracking both the position and the orientation.
    var isTracked: Bool {
        anchor?.trackingState == .positionOrientationTracked ? true : false
    }

    var pendingThrow = Throw()
    var triggeredThrow: Throw? = nil
    
    var pendingShake = Shake()
    var triggeredShake: Shake? = nil
}

struct Throw: Equatable {
    var peakSpeed: Float = 0
    var anchor: AccessoryAnchor? = nil
}

struct Shake: Equatable {
    enum Direction {
        case clockwise
        case counterClockwise
    }
    
    var peakAngularVelocity: Float = 0
    var currentDirection: Direction? = nil
    var oscillationCount: Int = 0
    var initialPosition: SIMD3<Float>? = nil
}
