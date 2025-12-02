/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that simulates camera motion by scaling, rotating, and translating the physics simulation root of a scene.
*/

import Combine
import SwiftUI
import RealityKit

final class RotationalCameraFollowSystem: System {
    var subscriptions: [AnyCancellable] = []
    
    let query = EntityQuery(where: .has(RotationalCameraFollowComponent.self))
    
    required init(scene: RealityKit.Scene) {
        scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self) {
            self.onWillSimulate(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    private func updateCameraRotation(rotationComponent: inout RotationalCameraFollowComponent, rotationEntity: Entity, deltaTime: Float) {
        // Update the current rotation angle.
        switch rotationComponent.mode {
        case .auto:
            // Get the direction to the follow target entity.
            var toFollowTarget = rotationComponent.followTarget.position(relativeTo: rotationEntity)
            toFollowTarget.y = 0

            // Calculate the angle between the follow target and the forward direction.
            var forwardDirection = rotationEntity.convert(direction: .forward, from: nil)
            forwardDirection.y = 0
            let angleBetweenForward = signedAngleBetween(from: toFollowTarget, to: forwardDirection, axis: [0, 1, 0])
            let isOutsideThreshold = abs(angleBetweenForward) > rotationComponent.rotationThreshold

            // Determine whether the target entity is in the camera rotation deadzone.
            let distance = length(SIMD3<Float>(rotationComponent.followTarget.position.x, 0, rotationComponent.followTarget.position.z))
            let isInHorizontalDeadzone = distance <= rotationComponent.deadZoneRadiusAndHeight.radius
            let height = rotationComponent.followTarget.position.y
            let isInDeadzone = (isInHorizontalDeadzone && height >= rotationComponent.deadZoneRadiusAndHeight.height)
                || height >= rotationComponent.deadzoneMinHeight

            // When outside the threshold, calculate a new rotation for the butte that brings the player back within the threshold.
            if isOutsideThreshold && isInDeadzone == false {
                let angleDifference = if angleBetweenForward > 0 {
                    angleBetweenForward - rotationComponent.rotationThreshold
                } else {
                    angleBetweenForward + rotationComponent.rotationThreshold
                }
                rotationComponent.targetAngle = rotationComponent.angle + angleDifference
            }

            // Increase the rotation smoothing when inside the deadzone, and decrease it back to its normal value when outside.
            if isInDeadzone {
                rotationComponent.dyanamicRotationSmoothing.lerpTo(1, smoothing: 1, deltaTime: deltaTime)
            } else {
                rotationComponent.dyanamicRotationSmoothing.lerpTo(rotationComponent.rotationSmoothing, smoothing: 1.5, deltaTime: deltaTime)
            }

            // Rotate the camera rotation angle toward the target rotation angle.
            rotationComponent.angle
                .lerpTo(rotationComponent.targetAngle, smoothing: rotationComponent.dyanamicRotationSmoothing, deltaTime: deltaTime)
        case .animated:
            // Animate the camera rotation target angle.
            rotationComponent.rotationAnimation?.updateAnimationTime(deltaTime: deltaTime)
            if let rotationAnimationAngle = rotationComponent.rotationAnimation?.value {
                rotationComponent.targetAngle = rotationAnimationAngle
            }
            // Animate the camera tilt target angle.
            rotationComponent.tiltAnimation?.updateAnimationTime(deltaTime: deltaTime)
            if let tiltAnimationAngle = rotationComponent.tiltAnimation?.value {
                rotationComponent.cameraTiltTarget = tiltAnimationAngle
            }
            // Animate the camera vertical offset position.
            rotationComponent.offsetAnimation?.updateAnimationTime(deltaTime: deltaTime)
            if let positionAnimationOffset = rotationComponent.offsetAnimation?.value {
                rotationComponent.cameraVerticalOffset = positionAnimationOffset
            }
            
            // Smooth toward the rotation and tilt target angles.
            let smoothing = rotationComponent.animationSmoothing
            rotationComponent.angle.lerpTo(rotationComponent.targetAngle, smoothing: smoothing, deltaTime: deltaTime)
            rotationComponent.cameraTiltAmount.lerpTo(rotationComponent.cameraTiltTarget, smoothing: smoothing, deltaTime: deltaTime)
        case .fixed:
            break
        }
    }
    
    @MainActor
    func updateCameraTiltAndOffset(rotationComponent: inout RotationalCameraFollowComponent, rotationEntity: Entity, deltaTime: Float) {
        // Determine if the current level is the tutorial.
        let isTutorial = rotationEntity.firstParent(withComponent: GameInfoComponent.self)?.component.isTutorial == true
        // Get the `CameraPoint` tilt.
        let updateTilt: Bool = rotationComponent.mode == .auto && isTutorial == false
        if updateTilt {
            let yProgress = rotationComponent.followTarget.position.y / 50
            for cameraPointIndex in 0..<(rotationComponent.cameraPoints.count - 1) {
                let currentCameraPoint = rotationComponent.cameraPoints[cameraPointIndex]
                let nextCameraPoint = rotationComponent.cameraPoints[cameraPointIndex + 1]
                if yProgress > currentCameraPoint.yPosition && yProgress < nextCameraPoint.yPosition {
                    rotationComponent.cameraTiltTarget = clampedRemap(value: yProgress,
                                                                    fromStart: currentCameraPoint.yPosition,
                                                                    fromEnd: nextCameraPoint.yPosition,
                                                                    toStart: currentCameraPoint.tiltAmount,
                                                                    toEnd: nextCameraPoint.tiltAmount)
                }
            }
        }
        
        // Calculate tilt and position additions.
        if updateTilt {
            rotationComponent.cameraTiltAmount.lerpTo(rotationComponent.cameraTiltTarget, smoothing: 0.5, deltaTime: deltaTime)
        }
        let tiltAddRot = simd_quatf(angle: rotationComponent.cameraTiltAmount * rotationComponent.cameraTiltMaxRotation, axis: [1, 0, 0])
        let tiltAddPosZ = rotationComponent.cameraTiltAmount * rotationComponent.cameraTiltMaxAddZ
        let tiltAddPosY = rotationComponent.cameraTiltAmount * rotationComponent.cameraTiltMaxAddY
        
        // Apply the rotation.
        rotationEntity.orientation = simd_mul(tiltAddRot, simd_quatf(angle: rotationComponent.angle, axis: [0, 1, 0]))
        
        // Apply the offset.
        switch rotationComponent.mode {
            case .auto:
                let targetY = rotationComponent.followTarget.position(relativeTo: rotationEntity.parent).y
                let cameraY = rotationEntity.position(relativeTo: rotationEntity.parent).y
                let targetOffset = targetY - cameraY
                rotationComponent.cameraVerticalOffset = clampedRemap(value: targetOffset,
                                                                    fromStart: rotationComponent.followTargetMinHeight,
                                                                    fromEnd: rotationComponent.followTargetMaxHeight,
                                                                    toStart: rotationComponent.cameraVerticalOffsetBottom,
                                                                    toEnd: rotationComponent.cameraVerticalOffsetTop)
            rotationEntity.position.lerpTo([0, rotationComponent.cameraVerticalOffset - tiltAddPosY, tiltAddPosZ],
                                         smoothing: rotationComponent.cameraPositionSmoothing,
                                         deltaTime: deltaTime)
            case .animated:
                rotationEntity.position.lerpTo([0, rotationComponent.cameraVerticalOffset, 0],
                                             smoothing: rotationComponent.cameraPositionAnimatedSmoothing,
                                             deltaTime: deltaTime)
            case .fixed:
                rotationEntity.position = [0, rotationComponent.cameraVerticalOffset, tiltAddPosZ]
        }
    }
    
    @MainActor
    func onWillSimulate(event: PhysicsSimulationEvents.WillSimulate) {
        let deltaTime = Float(event.deltaTime)
        
        guard let cameraEntity = event.simulationRootEntity,
              var cameraComponent = cameraEntity.components[RotationalCameraFollowComponent.self] else {
            return
        }

        // Scale with zoom.
        cameraEntity.scale = SIMD3<Float>(repeating: cameraComponent.cameraZoom)
        // Update the camera rotation.
        updateCameraRotation(rotationComponent: &cameraComponent, rotationEntity: cameraEntity, deltaTime: deltaTime)
        // Update the camera tilt and offset.
        updateCameraTiltAndOffset(rotationComponent: &cameraComponent, rotationEntity: cameraEntity, deltaTime: deltaTime)
        
        cameraEntity.components.set(cameraComponent)
    }
}
