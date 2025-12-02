/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for the rock-collector system that support the rock-friend follow and movement logic.
*/

import RealityKit
import RealityKitContent

extension RockCollectorSystem {
    @MainActor
    func onPhysicsSimulationWillSimulate (event: PhysicsSimulationEvents.WillSimulate) {
        guard let scene = event.simulationRootEntity?.scene,
              let gameState = scene.first(withComponent: GamePlayStateComponent.self)?.component,
              gameState.isPhysicsAllowed,
              let rockCollectorEntity = scene.first(withComponent: RockCollectorComponent.self)?.entity,
              let characterAnimation = rockCollectorEntity.firstParent(withComponent: CharacterAnimationComponent.self)?.component,
              let characterEntity = rockCollectorEntity.scene?.findEntity(id: characterAnimation.characterEntityId),
              var characterProgress = characterEntity.components[CharacterProgressComponent.self]
        else {
            return
        }

        addBreadcrumb(character: characterEntity, progress: &characterProgress)

        // `InvisibleCollider` is a kinematic rigid body, so you need to set its position or it won't follow the root entity.
        if let invisibleCollider = rockCollectorEntity.scene?.findEntity(named: "InvisibleCollider") {
            invisibleCollider.setPosition([0, 0, 0], relativeTo: invisibleCollider.parent)
        }
        let deltaTime = Float(event.deltaTime)
        for rockIndex in 0..<characterProgress.collectedRockFriends.count {
            let rockId = Entity.ID(characterProgress.collectedRockFriends[rockIndex].id)
            guard case let rockEntity as ModelEntity = rockCollectorEntity.scene?.findEntity(id: rockId) else {
                return
            }
            breadcrumbFollow(rockEntity: rockEntity,
                             rockIndex: rockIndex,
                             character: characterEntity,
                             progress: &characterProgress,
                             deltaTime: deltaTime)
        }

        characterEntity.components[CharacterProgressComponent.self] = characterProgress
    }

    @MainActor func addBreadcrumb (
        character: Entity,
        progress: inout CharacterProgressComponent
    ) {
        let lastCrumb = modNegativeSafe(progress.firstCrumb - 1, progress.breadcrumbs.count)

        let breadcrumbDistance: Float = 0.25
        if !progress.breadcrumbs.isEmpty && length(character.position - progress.breadcrumbs[lastCrumb].position) < breadcrumbDistance {
            return
        }

        // Make sure the player is on the ground.
        guard let characterMovement = character.components[CharacterMovementComponent.self] else {
            return
        }
        if !characterMovement.state.isOnGroundOrSlope {
            return
        }

        // Treat this as a circular buffer when it's full.
        if progress.breadcrumbs.count == CharacterProgressComponent.totalCrumbs {
            // Make sure the rock friends don't fall off the end.
            for index in progress.collectedRockFriends.indices {
                let rockFriend = progress.collectedRockFriends[index]
                if rockFriend.nextCrumbIndex == progress.firstCrumb {
                    progress.collectedRockFriends[index].nextCrumbIndex = (progress.firstCrumb + 1) % progress.breadcrumbs.count
                }
            }

            progress.firstCrumb = (progress.firstCrumb + 1) % progress.breadcrumbs.count

            let lastCrumb = modNegativeSafe(progress.firstCrumb - 1, progress.breadcrumbs.count)
            progress.breadcrumbs[lastCrumb] = Breadcrumb(position: character.position)
        } else {
            progress.breadcrumbs.append(Breadcrumb(position: character.position))
            progress.firstCrumb = 0
        }
        assert(progress.breadcrumbs.count <= CharacterProgressComponent.totalCrumbs)
    }

    @MainActor func findClosestBreadcrumbIndex(
        rock: Entity,
        character: Entity,
        progress: inout CharacterProgressComponent
    ) -> Int {
        var closestIndex = 0
        var closestDistanceSquared: Float = 0
        for (index, crumb) in progress.breadcrumbs.enumerated() {
            if crumb.reservedByRockIndex != -1 {
                continue
            }
            let distanceSquared = simd_length_squared(crumb.position - rock.position(relativeTo: character.parent))
            if index == 0 || distanceSquared < closestDistanceSquared {
                closestIndex = index
                closestDistanceSquared = distanceSquared
            }
        }
        return closestIndex
    }

    @MainActor
    func updateRockFriendJump(rockEntity: ModelEntity,
                              rockIndex: Int,
                              character: Entity,
                              progress: inout CharacterProgressComponent,
                              deltaTime: Float) {
        var rockFriend = progress.collectedRockFriends[rockIndex]
        if rockFriend.jumpT < rockFriend.totalJumpTime {
            // Follow the jump path.
            let nextJumpPathPos = rockFriend.jumpPos + rockFriend.jumpVel * rockFriend.jumpT +
                [0, -1, 0] * gravityStrength * 0.5 * rockFriend.jumpT * rockFriend.jumpT

            rockEntity.setPosition(nextJumpPathPos, relativeTo: character.parent)
            rockEntity.physicsMotion?.linearVelocity = .zero

            rockFriend.jumpT += deltaTime
        } else {

            rockEntity.components.set(
                AudioEventComponent(
                    resourceName: "RockDrop",
                    volumePercent: .random(in: 0.1...0.15),
                    speed: .random(in: 1.25...1.75)
                )
            )

            // Disable the jump state.
            rockFriend.totalJumpTime = -1
            if rockFriend.isLongJumping {
                // Do another jump after a long jump to simulate a bounce when the character lands.
                // This is a much shorter hop because the breadcrumb is closer.
                rockFriend.jumpNextFrame = true
                rockFriend.isLongJumping = false
            }
        }
        progress.collectedRockFriends[rockIndex] = rockFriend
    }
    
    @MainActor
    func getMoveParameters(prevPos: SIMD3<Float>,
                           rockIndex: Int,
                           rockFriend: inout CollectedRockFriend,
                           character: Entity,
                           progress: inout CharacterProgressComponent) -> MoveParams {
        var nextIndex = rockFriend.nextCrumbIndex

        // Rock friends are slightly smaller than the player so this can help them sit on the ground in
        // each frame, or just use the physics body collision.
        let rockFriendHeightOffset: Float = -0.2
        var nextPos = progress.breadcrumbs[nextIndex].position + [0, rockFriendHeightOffset, 0]

        // Check whether the character is at the end of the circular buffer.
        let endOfPath = ((nextIndex + 1) % progress.breadcrumbs.count) == progress.firstCrumb

        // Keep rocks a minimum distance away from the player.
        let minPlayerDistance: Float = 5
        let closeToPlayer = simd_distance(nextPos, character.position) < minPlayerDistance

        let nextNextIndex = (nextIndex + 1) % progress.breadcrumbs.count
        let canAdvance = !endOfPath && !closeToPlayer
        if canAdvance {
            // Advance to the next breadcrumb if you can.
            let reachedBreadcrumb = simd_distance(prevPos, nextPos) < 1
            let isCrumbOpen = progress.breadcrumbs[nextNextIndex].reservedByRockIndex == -1
            if reachedBreadcrumb && isCrumbOpen {
                // Release a breadcrumb.
                progress.breadcrumbs[nextIndex].reservedByRockIndex = -1

                nextIndex = nextNextIndex
                nextPos = progress.breadcrumbs[nextIndex].position
                rockFriend.nextCrumbIndex = nextIndex
                rockFriend.totalJumpTime = -1

                // Reserve a breadcrumb.
                progress.breadcrumbs[nextIndex].reservedByRockIndex = rockIndex
            }
        } else {
            // Modify `nextPos` for idle rock formation.
            let theta = 2 * Float.pi * Float(rockIndex) / Float(progress.collectedRockFriends.count)
            let formationRadius: Float = Float(progress.collectedRockFriends.count) / 6
            nextPos += [cos(theta), 0, sin(theta)] * formationRadius

            // Release a breadcrumb. Friends need to share the crumb for the formation.
            progress.breadcrumbs[nextIndex].reservedByRockIndex = -1
        }
        
        let offset = nextPos - prevPos
        let dir = simd_normalize(offset)
        let distance = simd_length(offset)

        let longJumpDistance: Float = 2

        // Jump if the distance to the next breadcrumb is large, but also jump randomly.
        let avgJumpsPerSecond: Float = 0.25
        let shouldJump = rockFriend.jumpNextFrame || distance > longJumpDistance || Float.random(in: 0...90) < avgJumpsPerSecond
        rockFriend.jumpNextFrame = false

        if shouldJump {
            // Release the breadcrumb so others can jump while the character is midair.
            progress.breadcrumbs[nextIndex].reservedByRockIndex = -1
        }
        
        return MoveParams(
            prevPos: prevPos,
            nextPos: nextPos,
            dir: dir,
            nextIndex: nextIndex,
            shouldJump: shouldJump,
            distance: distance,
            longJumpDistance: longJumpDistance
        )
    }
    
    @MainActor
    func doNearDestinationBehavior(moveParams: MoveParams,
                                   rockFriend: inout CollectedRockFriend,
                                   rockEntity: ModelEntity,
                                   character: Entity,
                                   progress: inout CharacterProgressComponent) {
        if moveParams.shouldJump {
            let friendShouldStillMakeASound = .random(in: 0...1) < sqrt(1 / Double(progress.collectedRockFriends.count + 1))
            if friendShouldStillMakeASound {
                rockEntity.components.set(AudioEventComponent(resourceName: "FriendQuip",
                                                              volumePercent: .random(in: 0.75...1),
                                                              speed: .random(in: 1...1.1)))
            }
            setupVerticalHop(rockFriend: &rockFriend, position: moveParams.prevPos, speed: 10)
        } else {
            // Lerp right to `nextPos` to avoid oscillation if the characters are close.
            let lerpedPos = mix(moveParams.prevPos, moveParams.nextPos, t: clamp01(5 * moveParams.deltaTime))
            rockEntity.setPosition(lerpedPos, relativeTo: character.parent)
            rockEntity.physicsMotion?.linearVelocity = .zero
        }
    }
    
    @MainActor
    func doNotNearDestinationBehavior(moveParams: MoveParams,
                                      rockFriend: inout CollectedRockFriend,
                                      rockIndex: Int,
                                      rockEntity: ModelEntity,
                                      progress: inout CharacterProgressComponent) {
        if moveParams.shouldJump {
            // Find the launch trajectory.
            var totalJumpTime: Float = 0
            let launch1 = ballisticVelocity(from: moveParams.prevPos,
                                            to: moveParams.nextPos,
                                            gravity: gravityStrength,
                                            time: &totalJumpTime,
                                            testNegative: false)
            let launch2 = ballisticVelocity(from: moveParams.prevPos,
                                            to: moveParams.nextPos,
                                            gravity: gravityStrength,
                                            time: &totalJumpTime,
                                            testNegative: true)
            var launch = launch1 ?? launch2
            if launch1 != nil && launch2 != nil {
                launch = launch1!.y > launch2!.y ? launch1 : launch2
            }

            let friendShouldSqueak = simd_length(launch!) > 20
            let friendShouldStillMakeASound = .random(in: 0...1) < sqrt(1 / Double(progress.collectedRockFriends.count + 1))
            if friendShouldSqueak && friendShouldStillMakeASound {
                rockEntity.components.set(AudioEventComponent(resourceName: "FriendSqueak",
                                                              volumePercent: .random(in: 0.75...1),
                                                              speed: .random(in: 1...1.1)))
            }

            if launch != nil {
                rockFriend.jumpVel = launch!
                rockFriend.jumpPos = moveParams.prevPos
                rockFriend.jumpT = 0
                rockFriend.totalJumpTime = totalJumpTime
                rockFriend.isLongJumping = moveParams.distance > moveParams.longJumpDistance
            }
        } else {
            let accel: Float = 100
            rockEntity.physicsMotion?.linearVelocity += moveParams.dir * accel * moveParams.deltaTime

            // Clamp to the maximum speed.
            let maxSpeed: Float = 10 + Float(rockIndex % 5)
            if simd_length(rockEntity.physicsMotion!.linearVelocity) > maxSpeed {
                rockEntity.physicsMotion!.linearVelocity = normalize(rockEntity.physicsMotion!.linearVelocity) * maxSpeed
            }
        }
    }
    
    @MainActor
    func updateRockFriendFollow(rockEntity: ModelEntity,
                                rockIndex: Int,
                                character: Entity,
                                progress: inout CharacterProgressComponent,
                                deltaTime: Float) {
        var rockFriend = progress.collectedRockFriends[rockIndex]
        let prevPos = rockEntity.position(relativeTo: character.parent)
        if rockFriend.nextCrumbIndex == -1 {
            let closestCrumb = findClosestBreadcrumbIndex(rock: rockEntity, character: character, progress: &progress)
            rockFriend.nextCrumbIndex = closestCrumb
            progress.breadcrumbs[rockFriend.nextCrumbIndex].reservedByRockIndex = rockIndex
        }

        var moveParams = getMoveParameters(prevPos: prevPos, rockIndex: rockIndex, rockFriend: &rockFriend, character: character, progress: &progress)
        moveParams.deltaTime = deltaTime
        
        let nearDestination = moveParams.distance < 1
        if nearDestination {
            doNearDestinationBehavior(moveParams: moveParams,
                                      rockFriend: &rockFriend,
                                      rockEntity: rockEntity,
                                      character: character,
                                      progress: &progress)
        } else {
            doNotNearDestinationBehavior(moveParams: moveParams,
                                         rockFriend: &rockFriend,
                                         rockIndex: rockIndex,
                                         rockEntity: rockEntity,
                                         progress: &progress)
        }
        
        progress.collectedRockFriends[rockIndex] = rockFriend
    }
    
    @MainActor
    func breadcrumbFollow (rockEntity: ModelEntity, rockIndex: Int, character: Entity, progress: inout CharacterProgressComponent, deltaTime: Float) {
        let prevPos = rockEntity.position(relativeTo: character.parent)
        let isJumping = progress.collectedRockFriends[rockIndex].totalJumpTime > 0
        if isJumping {
            updateRockFriendJump(rockEntity: rockEntity, rockIndex: rockIndex, character: character, progress: &progress, deltaTime: deltaTime)
        } else {
            updateRockFriendFollow(rockEntity: rockEntity, rockIndex: rockIndex, character: character, progress: &progress, deltaTime: deltaTime)
        }

        var rockVelocity = rockEntity.physicsMotion!.linearVelocity
        var speed = simd_length(rockVelocity)
        if speed <= 0.001 {
            // You might have to set velocity to zero to manually update the position,
            // and then compute the velocity.
            rockVelocity = (rockEntity.position(relativeTo: character.parent) - prevPos) / deltaTime
            speed = simd_length(rockVelocity)
        }

        if speed > 0.001 {
            let radius: Float = 0.5

            let surfaceNormal = SIMD3<Float>(0, 1, 0)
            let rotationAxis = simd_normalize(simd_cross(rockVelocity, surfaceNormal))
            if isnan(rotationAxis) != .zero {
                // You can achieve this if the velocity perfectly aligns with the surface normal.
                rockEntity.physicsMotion!.angularVelocity = 0.9 * rockEntity.physicsMotion!.angularVelocity
            } else {
                let angularSpeed = -speed / radius * (isJumping ? 0.5 : 1)

                rockEntity.physicsMotion!.angularVelocity = rotationAxis * angularSpeed
            }
        } else {
            rockEntity.physicsMotion!.angularVelocity = 0.9 * rockEntity.physicsMotion!.angularVelocity
        }
    }

    func setupVerticalHop(rockFriend: inout CollectedRockFriend, position: SIMD3<Float>, speed: Float) {
        rockFriend.jumpVel = [0, speed, 0]
        rockFriend.jumpPos = position
        rockFriend.jumpT = 0
        rockFriend.totalJumpTime = 2 * speed / gravityStrength
    }
    
    struct MoveParams {
        var prevPos: SIMD3<Float>
        var nextPos: SIMD3<Float>
        var dir: SIMD3<Float>
        var nextIndex: Int
        var shouldJump: Bool
        var distance: Float
        var longJumpDistance: Float
        var deltaTime: Float = 0
    }
}
