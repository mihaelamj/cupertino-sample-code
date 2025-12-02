/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that handles the rock-collection game mechanic and rock-friend follow logic.
*/

import Combine
import RealityKit
import RealityKitContent
import OSLog

final class RockCollectorSystem: System {
    
    static let outsideRangeRadius: Float = 0.7
    static let outsideRangeMaxSpeedRadius: Float = 1.5
    static let outsideRangeFollowSpeed: Float = 1800
    static let insideRangeFollowForce: Float = 600
    static let insideRangeDragForce: Float = 400
    static let pushOutForce: Float = 2000
    static let pushOutMaxRange: Float = 0.5
    static let pushOutMinRange: Float = 0.3
    static let followPrevRockDistance: Float = 0.05
    static let interiorColliderRadius: Float = 0.3
    let gravityStrength: Float = 50.0
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init (scene: RealityKit.Scene) {
        scene.subscribe(to: CollisionEvents.Began.self) {
            self.onCollisionBegan(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: RockCollectorComponent.self) {
            self.onDidAddRockCollector(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onGameStateChanged(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self) {
            self.onPhysicsSimulationWillSimulate(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidAddRockCollector (event: ComponentEvents.DidAdd) {
        // Create an invisible collider as a subentity of the rock collider.
        let shape = ShapeResource.generateSphere(radius: RockCollectorSystem.interiorColliderRadius)
        var collision = CollisionComponent(shapes: [shape], mode: .colliding)
        collision.filter = .init(group: GameSettings.collectedRockGroup, mask: GameSettings.collectedRockGroup)
        var physicsBody = PhysicsBodyComponent(shapes: [shape], mass: 1)
        physicsBody.mode = .kinematic
        physicsBody.isAffectedByGravity = false
        let invisibleCollider = Entity(components: [
            collision,
            physicsBody
        ])
        invisibleCollider.name = "InvisibleCollider"
        invisibleCollider.setParent(event.entity, preservingWorldTransform: false)
    }
    
    @MainActor
    func onCollisionBegan (event: CollisionEvents.Began) {
        guard event.entityA.components.has(RockCollectorComponent.self) == true,
                let rockPickup = event.entityB.components[RockPickupComponent.self],
                !rockPickup.isCollected,
                let characterAnimation = event.entityA.firstParent(withComponent: CharacterAnimationComponent.self)?.component,
                let characterEntity = event.entityA.scene?.findEntity(id: characterAnimation.characterEntityId)
        else {
            return
        }
        
        var rockFriend = CollectedRockFriend()
        rockFriend.id = event.entityB.id

        event.entityB.components.set(
            AudioEventComponent(
                resourceName: "FriendCollect",
                volumePercent: .random(in: 0.75...1),
                speed: .random(in: 1...1.1)
            )
        )

        setupVerticalHop(rockFriend: &rockFriend, position: event.entityB.position(relativeTo: characterEntity.parent), speed: 15)
        
        if let rockFriendChildName = event.entityB.children.first?.name, let rockFriendParentName = event.entityB.parent?.name {
            let rockFriendName = rockFriendParentName + "/" + rockFriendChildName
            rockFriend.name = rockFriendName
        }

        characterEntity.components[CharacterProgressComponent.self]?.collectedRockFriends.append(rockFriend)
        event.entityB.components[RockPickupComponent.self]?.isCollected = true
        event.entityB.components[RockPickupComponent.self]?.targetEntityId = event.entityA.id
        event.entityB.applyCollisionFilterRecursively(filter: .init(group: GameSettings.collectedRockGroup, mask: GameSettings.collectedRockGroup))
        
        // Activate a speech bubble as the character collects the rock friend.
        characterEntity.activateSpeechBubble(text: rockPickup.speechBubbleText, duration: rockPickup.speechBubbleDuration)
    }
    
    @MainActor
    func onGameStateChanged (event: ComponentEvents.DidChange) {
        guard let gameState = event.entity.components[GamePlayStateComponent.self],
              let rockPickups: QueryResult<Entity> = event.entity.scene?.performQuery(.init(where: .has(RockPickupComponent.self))) else { return }
        
        if gameState == .introAnimation || gameState == .starting {
            for rockPickupEntity in rockPickups {
                rockPickupEntity.components[RockPickupComponent.self]?.isCollected = false
                rockPickupEntity.components[RockPickupComponent.self]?.targetEntityId = 0
                rockPickupEntity.applyCollisionFilterRecursively(filter: .default)
                
                Task { @MainActor in
                    // This is necessary because the animation is still controlling the position,
                    // even though the playback controller is stopped.
                    try await Task.sleep(nanoseconds: UInt64(0.01 * Double(NSEC_PER_SEC)))
                    // Return the rock pickups to their original position.
                    rockPickupEntity.components[PhysicsMotionComponent.self]?.linearVelocity = .zero
                    rockPickupEntity.components[PhysicsMotionComponent.self]?.angularVelocity = .zero
                    rockPickupEntity.setOrientation(.init(), relativeTo: nil)
                    rockPickupEntity.setPosition(.zero, relativeTo: rockPickupEntity.parent)
                    if let (rockEntity, _) = rockPickupEntity.firstParent(withComponent: PhysicsMotionComponent.self) {
                        rockEntity.setPosition(.zero, relativeTo: rockPickupEntity.parent)
                        rockEntity.setOrientation(.init(), relativeTo: nil)
                        rockEntity.components[PhysicsMotionComponent.self]?.linearVelocity = .zero
                        rockEntity.components[PhysicsMotionComponent.self]?.angularVelocity = .zero
                    }
                }
            }
        }
    }
}
