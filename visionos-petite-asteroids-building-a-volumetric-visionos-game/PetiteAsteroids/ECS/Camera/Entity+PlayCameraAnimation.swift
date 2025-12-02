/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension for an entity that animates the rotational follow camera.
*/

import RealityKit

struct CameraAnimationParameters {
    var fromRotation: Float? = nil
    var toRotation: Float
    var rotationAnimationDuration: Float
    var fromTilt: Float? = nil
    var toTilt: Float
    var tiltAnimationDuration: Float
    var fromOffset: Float? = nil
    var toOffset: Float
    var offsetAnimationDuration: Float
    var timingFunction: EasingFunction = .easeInOutQuad
    var smoothing: Float = 0
}

extension Entity {
    func playCameraAnimation(parameters: CameraAnimationParameters) {
        guard var rotationalCamera = self.components[RotationalCameraFollowComponent.self] else {
            return
        }
        
        rotationalCamera.mode = .animated
        // Prepare the rotation animation.
        let fromRotation = parameters.fromRotation ?? ((rotationalCamera.angle > 0) ?
                                            rotationalCamera.angle.truncatingRemainder(dividingBy: 2 * .pi) :
                                            2 * .pi + rotationalCamera.angle.truncatingRemainder(dividingBy: 2 * .pi))
        let toRotation = abs(parameters.toRotation - fromRotation) > .pi ? parameters.toRotation + 2 * .pi : parameters.toRotation
        let rotationAnimation = RotationalCameraFollowComponent.CameraParameterAnimation(fromValue: fromRotation,
                                                                                         toValue: toRotation,
                                                                                         duration: parameters.rotationAnimationDuration,
                                                                                         timingFunction: parameters.timingFunction)
        rotationalCamera.targetAngle = rotationAnimation.fromValue
        rotationalCamera.angle = rotationAnimation.fromValue
        rotationalCamera.rotationAnimation = rotationAnimation
        // Prepare the tilt animation.
        let tiltAnimation = RotationalCameraFollowComponent.CameraParameterAnimation(fromValue: parameters.fromTilt ??
                                                                                                rotationalCamera.cameraTiltAmount,
                                                                                     toValue: parameters.toTilt,
                                                                                     duration: parameters.tiltAnimationDuration,
                                                                                     timingFunction: parameters.timingFunction)
        rotationalCamera.tiltAnimation = tiltAnimation
        // Prepare the offset animation.
        let offsetAnimation = RotationalCameraFollowComponent.CameraParameterAnimation(fromValue: parameters.fromOffset ?? self.position.y,
                                                                                       toValue: parameters.toOffset,
                                                                                       duration: parameters.offsetAnimationDuration,
                                                                                       timingFunction: parameters.timingFunction)
        rotationalCamera.offsetAnimation = offsetAnimation
        rotationalCamera.animationSmoothing = parameters.smoothing
        
        self.components.set(rotationalCamera)
    }
}
