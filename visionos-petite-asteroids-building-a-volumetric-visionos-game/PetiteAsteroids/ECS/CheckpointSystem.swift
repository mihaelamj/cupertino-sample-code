/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls activating and resetting checkpoints.
*/

import Combine
import RealityKit
import RealityKitContent

final class CheckpointSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init (scene: Scene) {
        scene.subscribe(to: CollisionEvents.Began.self) {
            self.onCollisionBegan(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onGameStateChanged(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onCollisionBegan (event: CollisionEvents.Began) {
        // Only consider collisions between the character and unclaimed checkpoints.
        guard event.entityA.components.has(CharacterMovementComponent.self) == true,
              let checkpoint = event.entityB.components[CheckpointComponent.self],
              checkpoint.isClaimed == false else { return }
        
        // Claim the checkpoint.
        event.entityB.components[CheckpointComponent.self]?.isClaimed = true

        // Play a sound when claiming the checkpoint.
        event.entityB.components.set(AudioEventComponent(resourceName: "Checkpoint\(checkpoint.index + 1)"))
        
        // Find the current spawn point entity.
        if let spawnPointEntity = event.entityA.scene?.first(withComponent: CharacterSpawnPointComponent.self)?.entity {
            let currentSpawnPos = spawnPointEntity.position(relativeTo: nil)
            let checkpointPos = event.entityB.position(relativeTo: nil)
            // If the checkpoint is above the current spawn point,
            // move the spawn point to the checkpoint so the player respawns at the checkpoint's position.
            if checkpointPos.y > currentSpawnPos.y {
                spawnPointEntity.setPosition(checkpointPos, relativeTo: nil)
            }
        }
        
        // Play the activate animation on the checkpoint entity.
        _ = event.entityB.playAnimation(name: "Activate")
    }
    
    @MainActor
    func onGameStateChanged (event: ComponentEvents.DidChange) {
        // Ensure the game enters the `.starting` state, and perform a query for all the checkpoints.
        guard let gameState = event.entity.components[GamePlayStateComponent.self],
              gameState == .starting,
              let checkpoints = event.entity.scene?.performQuery(.init(where: .has(CheckpointComponent.self))) else { return }

        // Reset every checkpoint in the scene.
        checkpoints
            .sorted { $0.position(relativeTo: nil).y < $1.position(relativeTo: nil).y }
            .enumerated()
            .forEach { index, checkpointEntity in
                checkpointEntity.components[CheckpointComponent.self]?.index = index
                checkpointEntity.components[CheckpointComponent.self]?.isClaimed = false
                _ = checkpointEntity.playAnimation(name: "Reset")
            }
    }
}
