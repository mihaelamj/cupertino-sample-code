/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for the character movement system that support collision handling.
*/

import RealityKit
import RealityKitContent

extension CharacterMovementSystem {
    @MainActor
    func updateCollisionClassification(characterEntity: Entity, collisionEntity: Entity, contacts: [Contact]) {
        guard characterEntity.components.has(CharacterMovementComponent.self),
            var collisionNormal = contacts.first?.normal else {
            return
        }
        
        // Ignore specific entities.
        guard !collisionEntity.components.has(RockCollectorComponent.self),
              !collisionEntity.components.has(CheckpointComponent.self),
              !collisionEntity.components.has(SpeechBubbleTriggerComponent.self),
              !collisionEntity.components.has(PlatformAnimationMarkerComponent.self),
              collisionEntity.components[CollisionComponent.self]?.filter.group != GameCollisionGroup.volumeBoundary.collisionGroup else {
            return
        }
        
        // Normalize the collision normal.
        collisionNormal = normalize(collisionNormal)
        
        let collisionDot = dot(collisionNormal, [0, 1, 0])
        let classification: CollisionClassification = if collisionDot < -GameSettings.isWallDotProductThreshold {
            .ceiling
        } else if collisionDot < GameSettings.isWallDotProductThreshold {
            .wall(normal: collisionNormal)
        } else if collisionDot < GameSettings.isSlopeDotProductThreshold {
            .slope(normal: collisionNormal)
        } else {
            .ground
        }
        
        characterEntity.components[CharacterMovementComponent.self]?.collisionClassificationByEntity[collisionEntity] = classification
    }
    
    @MainActor
    func onCollisionBegan(event: CollisionEvents.Began) {
        guard let (_, gameState) = event.entityA.scene?.first(withComponent: GamePlayStateComponent.self),
              gameState.isPhysicsAllowed else {
            return
        }
        
        updateCollisionClassification(characterEntity: event.entityA, collisionEntity: event.entityB, contacts: event.contacts)
        
        guard var characterMovement = event.entityA.components[CharacterMovementComponent.self] else { return }
        
        // Start tracking the current platform if the right component exists.
        if let platformIndex = event.entityB.components[PlatformAnimationMarkerComponent.self]?.platformIndex {
            event.entityA.components[CharacterMovementComponent.self]?.currentPlatformIndex = platformIndex
            // Return early because there's nothing left to do for this particular kind of entity.
            return
        }
        
        // Use the stored collision classifications of the character movement component to detect bounces.
        if let collisionClassification = characterMovement.collisionClassificationByEntity[event.entityB] {
            
            // Detect a bounce if the impulse is greater than a specific threshold and this collision is with the ground or a slope.
            let isBounce = event.impulse > GameSettings.bounceImpulseThreshold && collisionClassification.isGroundOrSlope
            if isBounce {
                
                // Detect whether the character bounces off the level boundary.
                let isLevelBoundary = event.entityB.components[CollisionComponent.self]?.filter.group == GameSettings.levelBoundaryGroup
                if isLevelBoundary == false {
                    // Play a bounce sound effect on entity A, and modulate the volume based on the bounce impulse.
                    let volumePercent = max(min(1, event.impulse * GameSettings.dropAudioImpulseMultiplier), 0)
                    let audioEvent = AudioEventComponent(resourceName: "RockDrop", volumePercent: volumePercent)
                    event.entityA.components.set(audioEvent)
                }
                
                // Use the dot product to determine if the impulse is up.
                let dot = simd_dot(event.impulseDirection, [0, 1, 0])
                let isImpulseUp = dot > 0.8
                
                // If the character is on a platform and the impulse is up, begin the platform offset animation.
                if let currentPlatformIndex = characterMovement.currentPlatformIndex, isImpulseUp,
                   let platforms = event.entityA.scene?.findEntity(named: "Platforms")?.first(withComponent: ModelComponent.self)?.entity {
                    
                    // Clamp the impulse when calculating the animation configuration to avoid moving the platform too much.
                    let clampedImpulse = max(min(GameSettings.platformOffsetAnimationMaxImpulse, event.impulse), 0) *
                    GameSettings.platformOffsetAnimationAmplitudeFactor
                    
                    // Create an animation component using the calculated values.
                    var animationComponent = PlatformOffsetAnimationComponent(platformIndex: currentPlatformIndex,
                                                                               offsetY: .leastNormalMagnitude * -1,
                                                                               velocity: -clampedImpulse / 90)
                    
                    // Because subsequent animation components override any previous animation,
                    // allow the previous animation to affect the new animation.
                    if let existingAnimation = platforms.components[PlatformOffsetAnimationComponent.self],
                       existingAnimation.platformIndex == animationComponent.platformIndex {
                        animationComponent.velocity += existingAnimation.velocity
                        animationComponent.offsetY = existingAnimation.offsetY
                    }
                    platforms.components.set(animationComponent)
                }
            }
            
            // Cache the animation entity on the character movement component.
            if characterMovement.animationEntity == nil {
                let animationEntity = event.entityA.scene!.first(withComponent: CharacterAnimationComponent.self)?.entity
                characterMovement.animationEntity = animationEntity
                event.entityA.components.set(characterMovement)
            }
            
            // If no squash animation is playing, begin squashing the animation entity.
            if let squashEntity = characterMovement.animationEntity?.findEntity(named: "CharacterSquash"),
               squashEntity.components.has(SquashAnimationComponent.self) == false {
                let clampedSquashImpulse = max(min(GameSettings.maxSquashImpulse, event.impulse), 0)
                let multiplier = clampedSquashImpulse / GameSettings.maxSquashImpulse
                let squashAnimation = SquashAnimationComponent(multiplier: multiplier)
                squashEntity.components.set(squashAnimation)
            }
        }
    }
    
    @MainActor
    func onCollisionUpdated(event: CollisionEvents.Updated) {
        guard
            let (_, gameState) = event.entityA.scene?.first(withComponent: GamePlayStateComponent.self),
            gameState.isPhysicsAllowed
        else {
            return
        }
        updateCollisionClassification(characterEntity: event.entityA, collisionEntity: event.entityB, contacts: event.contacts)
    }
    
    @MainActor
    func onCollisionEnded(event: CollisionEvents.Ended) {
        guard let (_, gameState) = event.entityA.scene?.first(withComponent: GamePlayStateComponent.self),
              gameState.isPhysicsAllowed,
              let characterMovement = event.entityA.components[CharacterMovementComponent.self] else {
            return
        }
        event.entityA.components[CharacterMovementComponent.self]?.collisionClassificationByEntity[event.entityB] = nil
        
        // Stop tracking the current platform.
        if event.entityB.components[PlatformAnimationMarkerComponent.self]?.platformIndex == characterMovement.currentPlatformIndex {
            event.entityA.components[CharacterMovementComponent.self]?.currentPlatformIndex = nil
        }
    }
    
    @MainActor
    func updateCharacterStateWithCurrentCollisions (movementComponent: inout CharacterMovementComponent) {
        if movementComponent.collisionClassificationByEntity.count(where: { $0.value == .ground }) > 0 {
            movementComponent.state = .onGround
            movementComponent.canJumpTimer = GameSettings.jumpCoyoteTime
        } else if movementComponent.collisionClassificationByEntity.count(where: { if case .slope = $0.value { true } else { false } }) > 0 {
            movementComponent.state = .onSlope
            movementComponent.canJumpTimer = GameSettings.jumpCoyoteTime
            movementComponent.isSlidingTimer = GameSettings.slideCoyoteTime
            var averageSlopeNormal = movementComponent.collisionClassificationByEntity.reduce(SIMD3<Float>.zero) {
                if case .slope(let normal) = $1.value {
                    return $0 + normal
                }
                return .zero
            }
            averageSlopeNormal = simd_length_squared(averageSlopeNormal) == 0 ? .zero : normalize(averageSlopeNormal)
            movementComponent.lastSlopeNormal = averageSlopeNormal
        } else if movementComponent.collisionClassificationByEntity.count(where: { if case .wall = $0.value { true } else { false } }) > 0 {
            movementComponent.state = .onWall
            movementComponent.canWallJumpTimer = GameSettings.wallJumpCoyoteTime
            // Get the average normal of all the walls the character is currently touching.
            var averageWallNormal = movementComponent.collisionClassificationByEntity.reduce(SIMD3<Float>.zero) {
                if case .wall(let normal) = $1.value {
                    return $0 + normal
                }
                return .zero
            }
            averageWallNormal = simd_length_squared(averageWallNormal) == 0 ? .zero : normalize(averageWallNormal)
            movementComponent.lastWallNormal = averageWallNormal
        } else {
            movementComponent.state = .inAir
        }
    }
    
    @MainActor
    func updateCharacterBoundaryCollisionResponse(movementComponent: inout CharacterMovementComponent, character: Entity) {
        let enableLevelBoundaryCollisions = movementComponent.disableLevelBoundaryTimer > 0 && movementComponent.canCollideWithLevelBoundary
        character.components[CollisionComponent.self]?.filter.mask = enableLevelBoundaryCollisions ?
            .all :
            .all.subtracting(GameCollisionGroup.levelBoundary.collisionGroup)
    }
}
