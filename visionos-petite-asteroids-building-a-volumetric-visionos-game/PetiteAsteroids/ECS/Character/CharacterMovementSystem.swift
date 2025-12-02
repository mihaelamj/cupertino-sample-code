/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the character's movement.
*/

import Combine
import RealityKit
import RealityKitContent

final class CharacterMovementSystem: System {
    var subscriptions: [AnyCancellable] = .init()
    required init(scene: RealityKit.Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: CharacterMovementComponent.self) {
            self.didAddCharacterMovementComponent(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: CollisionEvents.Began.self) {
            self.onCollisionBegan(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: CollisionEvents.Updated.self) {
            self.onCollisionUpdated(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: CollisionEvents.Ended.self) {
            self.onCollisionEnded(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: PhysicsSimulationEvents.WillSimulate.self) {
            self.onPhysicsSimulationWillSimulate(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: NotificationComponent.self) {
            self.onDidAddNotificationComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidAddNotificationComponent(event: ComponentEvents.DidAdd) {
        guard let notification = event.entity.components[NotificationComponent.self],
              let scene = event.entity.scene,
              let gamePlayStateEntity = event.entity.firstParent(withComponent: GamePlayStateComponent.self)?.entity else {
            return
        }
        
        switch notification.name {
        case GameSettings.respawnNotification:
            // Ignore notifications that the system sends too quickly.
            guard let (characterEntity, characterMovement) = scene.first(withComponent: CharacterMovementComponent.self),
                  characterMovement.canRespawnTimer <= 0,
                  let spawnPointEntity = gamePlayStateEntity.first(withComponent: CharacterSpawnPointComponent.self)?.entity else {
                return
            }
            
            // Reset the respawn timer.
            characterEntity.components[CharacterMovementComponent.self]?.canRespawnTimer = GameSettings.canRespawnDurationThreshold
            
            // Reset the movement of the character.
            characterEntity.components[CharacterMovementComponent.self]?.velocity = .zero
            characterEntity.components[PhysicsMotionComponent.self]?.linearVelocity = .zero
            characterEntity.components[PhysicsMotionComponent.self]?.angularVelocity = .zero
            
            // Move the character entity to the spawn position.
            let respawnPos = spawnPointEntity.position(relativeTo: characterEntity.parent)
            characterEntity.setPosition(respawnPos, relativeTo: characterEntity.parent)
        default:
            break
        }
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        onGamePlayStateChanged(gamePlayStateEntity: event.entity)
    }
    
    @MainActor
    func onGamePlayStateChanged(gamePlayStateEntity: Entity) {
        guard let gamePlayState = gamePlayStateEntity.components[GamePlayStateComponent.self],
                let (characterEntity, _) = gamePlayStateEntity.scene?.first(withComponent: CharacterMovementComponent.self) else {
            return
        }
        
        if gamePlayState.isBeforeGamePlay {
            // Reset the character's movement component when the game is starting.
            characterEntity.components.set(CharacterMovementComponent())
            // Zero out the character's velocities.
            characterEntity.components[PhysicsMotionComponent.self]?.linearVelocity = .zero
            characterEntity.components[PhysicsMotionComponent.self]?.angularVelocity = .zero
        }
        
        // Position the character at the spawn point on start.
        if gamePlayState == .starting,
           let spawnPointEntity = gamePlayStateEntity.scene?.first(withComponent: CharacterSpawnPointComponent.self)?.entity {
            characterEntity.position = spawnPointEntity.position(relativeTo: characterEntity.parent)
        }
    }
    
    @MainActor
    func didAddCharacterMovementComponent(event: ComponentEvents.DidAdd) {
        // Prepare the character's shape.
        let sphereShape = ShapeResource.generateSphere(radius: GameSettings.characterRadius)
        // Add a physics body.
        var physicsBody = PhysicsBodyComponent(shapes: [sphereShape], mass: 8)
        physicsBody.isContinuousCollisionDetectionEnabled = true
        physicsBody.material = .generate(friction: GameSettings.characterFriction, restitution: GameSettings.characterRestitution)
        physicsBody.isAffectedByGravity = false
        event.entity.components.set(physicsBody)
        // Add a physics motion.
        event.entity.components.set(PhysicsMotionComponent())
        // Add a collision.
        event.entity.components.set(CollisionComponent(shapes: [sphereShape], collisionOptions: .fullContactInformation))
    }
}
