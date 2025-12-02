/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the state for the rotational camera follow system.
*/

import SwiftUI
import RealityKit

struct RotationalCameraFollowComponent: Component {
    struct CameraParameterAnimation {
        var fromValue: Float
        var toValue: Float
        var duration: Float
        var animationTime: Float = 0
        var timingFunction: EasingFunction = .easeInOutQuad
        var value: Float { simd_mix(fromValue, toValue, timingFunction.evaluate(animationTime)) }
        
        mutating func updateAnimationTime(deltaTime: Float) {
            animationTime = min(animationTime + deltaTime / duration, 1)
        }
    }

    struct CameraPoint {
        var yPosition: Float
        var tiltAmount: Float
    }

    enum RotationalCameraMode {
        case auto
        case animated
        case fixed
    }
    
    var followTarget: Entity
    var cameraZoom: Float
    var followTargetMinHeight: Float = 0
    var followTargetMaxHeight: Float = 1
    var cameraVerticalOffsetBottom: Float = 0
    var cameraVerticalOffsetTop: Float = -0.6
    var cameraVerticalOffset: Float = 0
    var angle: Float = 0
    // MARK: - Camera points
    var cameraPoints: [CameraPoint] = [
        CameraPoint(yPosition: -1.0, tiltAmount: 0.0),
        CameraPoint(yPosition: 0.3, tiltAmount: 0.0),
        CameraPoint(yPosition: 0.4, tiltAmount: 0.1),
        CameraPoint(yPosition: 0.6, tiltAmount: 0.3),
        CameraPoint(yPosition: 0.95, tiltAmount: 0.8),
        CameraPoint(yPosition: 2.0, tiltAmount: 0.8)
    ]
    var cameraTiltTarget: Float = 0
    var cameraTiltAmount: Float = 0
    var cameraTiltMaxRotation: Float = 0.8
    var cameraTiltAngle: Float { cameraTiltAmount * cameraTiltMaxRotation }
    var cameraTiltMaxAddY: Float = -0.5
    var cameraTiltMaxAddZ: Float = -0.6
    // MARK: - Dynamic camera
    var targetAngle: Float = 0
    var rotationThreshold: Float = .pi / 16
    var rotationSmoothing: Float = 0.3
    var cameraScaleSmoothing: Float = 0.3
    var cameraPositionSmoothing: Float = 0.3
    var cameraPositionAnimatedSmoothing: Float = 3
    var mode: RotationalCameraMode = .auto
    // MARK: - Direction mode
    let deadZoneRadiusAndHeight: (radius: Float, height: Float) = (14, 49)
    let deadzoneMinHeight: Float = 53
    var dyanamicRotationSmoothing: Float = 0.3
    // MARK: - Animation mode
    var tiltAnimation: CameraParameterAnimation?
    var rotationAnimation: CameraParameterAnimation?
    var offsetAnimation: CameraParameterAnimation?
    var animationSmoothing: Float = 0.05
}
