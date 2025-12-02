/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for the character movement system that support moving the character with physics.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension CharacterMovementSystem {
    @MainActor
    func updateTimers(movementComponent: inout CharacterMovementComponent, progressComponent: inout CharacterProgressComponent, deltaTime: Float) {
        progressComponent.runDurationTimer += deltaTime
        movementComponent.jumpBufferTimer -= deltaTime
        movementComponent.canJumpTimer -= deltaTime
        movementComponent.canWallJumpTimer -= deltaTime
        movementComponent.isSlidingTimer -= deltaTime
        movementComponent.canRespawnTimer -= deltaTime
        movementComponent.jumpGravityTimer -= deltaTime
        
        if movementComponent.state == .inAir && movementComponent.positionDelta.y < 0 {
            movementComponent.fallingTimer += deltaTime
        } else if movementComponent.state == .onGround || movementComponent.state == .onSlope {
            movementComponent.fallingTimer = 0
        }
        
        if movementComponent.state.isOnGroundOrSlope {
            movementComponent.disableLevelBoundaryTimer = GameSettings.levelBoundaryDisappearTime
        } else {
            movementComponent.disableLevelBoundaryTimer -= deltaTime
        }
    }
    
    @MainActor
    private func getInputMoveDirection(movementComponent: inout CharacterMovementComponent,
                                       velocityXZ: SIMD3<Float>,
                                       character: Entity,
                                       physicsRoot: Entity) -> SIMD3<Float> {
        // Convert the input move direction to physics root space.
        var inputMoveDirection = physicsRoot.convert(direction: movementComponent.inputMoveDirection, from: nil) * physicsRoot.scale.x
        
        // Overide input by moving toward the target position if one is set.
        if let targetMovePosition = movementComponent.targetMovePosition ?? movementComponent.targetJumpPosition {
            
            // Get the direction and distance to the target position.
            var toTarget = targetMovePosition - character.position(relativeTo: physicsRoot)
            toTarget.y = 0
            let distanceToTarget = length(toTarget)
            
            // Get the stopping distance given the current velocity.
            let stoppingDistance = ProjectileMotionUtilities.calculateBrakingDistance(velocity: length(velocityXZ),
                                                                                      acceleration: GameSettings.stoppingAcceleration)
            
            // Stop the input if within stopping distance of the target.
            if distanceToTarget <= stoppingDistance {
                inputMoveDirection = .zero
                movementComponent.targetMovePosition = nil
                movementComponent.targetJumpPosition = nil
            // Otherwise, set the input to move in the direction of the target.
            } else {
                inputMoveDirection = (toTarget / distanceToTarget) * clamp01(movementComponent.targetMoveInputStrength)
            }
        }
        
        return inputMoveDirection
    }

    @MainActor
    func updateVelocityWithMovement(movementComponent: inout CharacterMovementComponent, character: Entity, physicsRoot: Entity, deltaTime: Float) {
        var velocityXZ = SIMD3<Float>(movementComponent.velocity.x, 0, movementComponent.velocity.z)
        
        // Get the input direction.
        let inputMoveDirection = getInputMoveDirection(
            movementComponent: &movementComponent,
            velocityXZ: velocityXZ,
            character: character,
            physicsRoot: physicsRoot
        )
        
        // Determine whether the input is in the same direction that the character is already moving.
        let isMaintainingHeading = dot(inputMoveDirection, velocityXZ) > 0
        
        // When the input aligns with the character movement, accelerate normally;
        // otherwise, increase the acceleration to change the direction more quickly.
        let acceleration = GameSettings.accelerationFor(state: movementComponent.state)
        let moveAcceleration = inputMoveDirection * acceleration * (isMaintainingHeading ? 1 : GameSettings.reverseDirectionAccelerationFactor)
        
        // Update the velocity with the acceleration.
        velocityXZ += moveAcceleration * deltaTime

        // Determine whether the character is currently moving up a slope.
        let isSliding = movementComponent.isSlidingTimer > 0
        let slopeNormal = physicsRoot.convert(normal: movementComponent.lastSlopeNormal, from: nil)
        let isSlidingDownSlope = isSliding && dot(slopeNormal, velocityXZ) > 0
        
        // Determine the character's maximum move speed given the current surface they're touching.
        let maxMoveSpeed = if isSlidingDownSlope {
            GameSettings.onDownSlopeMaxMoveSpeed
        } else {
            GameSettings.maxMoveSpeedFor(state: movementComponent.state)
        }
        
        // When the character is moving too fast, apply a negative acceleration that slows them down to their maximum move speed.
        var currentMoveSpeed = simd_length(velocityXZ)
        if currentMoveSpeed > maxMoveSpeed {
            let speedDifference = currentMoveSpeed - maxMoveSpeed
            
            // Calculate the strength of the slowing acceleration, clamping it below the current speed difference
            // to ensure it doesn't slow the character below their maximum speed.
            let slowingAccelerationStrength = min(acceleration * GameSettings.slowingAccelerationFactor * deltaTime, speedDifference)
            
            // Apply the slowing acceleration.
            velocityXZ -= velocityXZ / currentMoveSpeed * slowingAccelerationStrength
        }
        
        // Apply a stopping acceleration to bring the player down to their target move speed.
        currentMoveSpeed = simd_length(velocityXZ)
        let targetMoveSpeed = maxMoveSpeed * (isSlidingDownSlope ? 1 : simd_length(inputMoveDirection))
        if currentMoveSpeed > targetMoveSpeed {
            let speedDifference = currentMoveSpeed - targetMoveSpeed
            
            let slowingAccelerationStrength = min(GameSettings.stoppingAcceleration * deltaTime, speedDifference)
            
            velocityXZ -= velocityXZ / currentMoveSpeed * slowingAccelerationStrength
        }
        
        movementComponent.velocity.x = velocityXZ.x
        movementComponent.velocity.z = velocityXZ.z
    }

    @MainActor
    func updateVelocityWithGravity(movementComponent: inout CharacterMovementComponent, physicsRoot: Entity, deltaTime: Float) {
        // Apply acceleration to the velocity due to gravity.
        let velocityXZ = SIMD3<Float>(movementComponent.velocity.x, 0, movementComponent.velocity.z)
        let slopeNormal = physicsRoot.convert(normal: movementComponent.lastSlopeNormal, from: nil)
        let isMovingUpSlope = dot(slopeNormal, velocityXZ) < 0
        let gravity = if movementComponent.state == .onSlope && isMovingUpSlope {
            GameSettings.upSlopeGravity
        } else {
            movementComponent.jumpGravityTimer > 0 ? GameSettings.jumpGravity : GameSettings.baseGravity
        }
        movementComponent.velocity.y += gravity * deltaTime
    }

    @MainActor
    func updateVelocityWithJump(movementComponent: inout CharacterMovementComponent, character: Entity, physicsRoot: Entity) {
        let wasJumpPressed = movementComponent.jumpBufferTimer > 0
        let canJump = movementComponent.canJumpTimer > 0
        let canWallJump = !movementComponent.didWallJump && movementComponent.canWallJumpTimer > 0
        if wasJumpPressed && (canJump || canWallJump) {
            // Perform a ground jump if the character touches the ground more recently than they touch a wall.
            if canJump {
                character.position.y += GameSettings.jumpSurfaceSeparation
                movementComponent.velocity.y = movementComponent.jumpSpeed
                movementComponent.jumpGravityTimer = movementComponent.jumpGravityDuration
                movementComponent.canJumpTimer = 0
                movementComponent.disableLevelBoundaryTimer = 0
            // Otherwise, perform a wall jump.
            } else if canWallJump {
                character.position += normalize(movementComponent.velocity) * GameSettings.jumpSurfaceSeparation
                let wallNormal = physicsRoot.convert(normal: movementComponent.lastWallNormal, from: nil)
                let wallJumpHorizontalVelocity = normalize(SIMD3<Float>(wallNormal.x, 0, wallNormal.z)) * movementComponent.wallJumpHorizontalSpeed
                movementComponent.velocity = [wallJumpHorizontalVelocity.x, movementComponent.wallJumpVerticalSpeed, wallJumpHorizontalVelocity.z]
                movementComponent.jumpGravityTimer = movementComponent.wallJumpGravityDuration
                movementComponent.canWallJumpTimer = 0
                movementComponent.disableLevelBoundaryTimer = 0
                movementComponent.didWallJump = true
            }

            movementComponent.jumpBufferTimer = 0
        }
        
        // Stop moving to the target jump position if the input move direction has a nonzero magnitude,
        // or the character is able to jump again.
        if length_squared(movementComponent.inputMoveDirection) > 0 || movementComponent.canJumpTimer > 0 {
            movementComponent.targetJumpPosition = nil
        }
    }
    
    @MainActor
    func applyVerticalVelocityContraints (movementComponent: inout CharacterMovementComponent) {
        let isOnWall = movementComponent.state == .onWall
        
        // Decrease the character's upward velocity as soon as they grab onto a wall.
        if isOnWall && movementComponent.velocity.y > 0 {
            movementComponent.velocity.y *= 0.95
        }
        
        // Limit the vertical velocity to the maximum fall speed.
        let maxFallSpeed = GameSettings.maxFallSpeedFor(state: movementComponent.state)
        movementComponent.velocity.y = max(movementComponent.velocity.y, maxFallSpeed)
    }

    @MainActor
    func updateAngularVelocity (movementComponent: inout CharacterMovementComponent, deltaTime: Float) {
        if movementComponent.state == .inAir {
            movementComponent.angularVelocity *= 1 - (deltaTime * 5)
        } else {
            let axis = simd_cross(movementComponent.velocity, [0, -1, 0])
            let distance = length(movementComponent.velocity) * deltaTime
            let circumference = GameSettings.characterRadius * 2 * .pi
            let rollRadians = (2 * .pi) * (distance / circumference)
            let rollRotation = simd_quatf(angle: rollRadians, axis: axis)
            let spatialRotation = Rotation3D(rollRotation)
            let euler = spatialRotation.eulerAngles(order: .xyz)
            movementComponent.angularVelocity = [Float(euler.angles.x), Float(euler.angles.y), Float(euler.angles.z)] * 2 * .pi
        }
    }

    @MainActor
    func onPhysicsSimulationWillSimulate(event: PhysicsSimulationEvents.WillSimulate) {
        guard
            let scene = event.simulationRootEntity?.scene,
            let (_, gameState) = scene.first(withComponent: GamePlayStateComponent.self),
            gameState.isPhysicsAllowed
        else {
            return
        }

        for characterEntity in scene.performQuery(.init(where: .has(CharacterMovementComponent.self))) {
            guard var movementComponent = characterEntity.components[CharacterMovementComponent.self],
                  var progressComponent = characterEntity.components[CharacterProgressComponent.self],
                  let physicsRoot = PhysicsSimulationComponent.nearestSimulationEntity(for: characterEntity),
                  event.simulationRootEntity == physicsRoot else {
                return
            }

            let deltaTime = Float(event.deltaTime)

            // Get the current velocity.
            movementComponent.velocity = characterEntity.components[PhysicsMotionComponent.self]?.linearVelocity ?? .zero
            let currentPosition = characterEntity.position(relativeTo: physicsRoot)
            movementComponent.positionDelta = currentPosition - movementComponent.previousPosition
            movementComponent.previousPosition = currentPosition

            updateCharacterStateWithCurrentCollisions(movementComponent: &movementComponent)
            updateTimers(movementComponent: &movementComponent, progressComponent: &progressComponent, deltaTime: deltaTime)
            updateVelocityWithMovement(movementComponent: &movementComponent, character: characterEntity,
                                       physicsRoot: physicsRoot,
                                       deltaTime: deltaTime)
            updateVelocityWithGravity(movementComponent: &movementComponent, physicsRoot: physicsRoot, deltaTime: deltaTime)
            updateVelocityWithJump(movementComponent: &movementComponent, character: characterEntity, physicsRoot: physicsRoot)
            updateAngularVelocity(movementComponent: &movementComponent, deltaTime: deltaTime)
            applyVerticalVelocityContraints(movementComponent: &movementComponent)
            updateCharacterBoundaryCollisionResponse(movementComponent: &movementComponent, character: characterEntity)
            
            movementComponent.currentSpeed = simd_length(movementComponent.velocity)
            
            if movementComponent.state == .onGround, movementComponent.positionDelta == .zero {
                movementComponent.didWallJump = false
            }

            // Apply the velocity.
            characterEntity.components[PhysicsMotionComponent.self]?.linearVelocity = movementComponent.velocity
            characterEntity.components[PhysicsMotionComponent.self]?.angularVelocity = movementComponent.angularVelocity

            // Update the movement component.
            characterEntity.components.set(movementComponent)
            characterEntity.components.set(progressComponent)
        }
    }
}
