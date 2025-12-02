/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that causes the game to enter the outro animation state when the character collides with the win-game trigger.
*/

import Combine
import RealityKit
import RealityKitContent
class WinGameTriggerSystem: System {
    let query = EntityQuery(where: .has(WinGameTriggerComponent.self))
    
    var subscriptions: [AnyCancellable] = .init()
    required init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self,
        componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: CollisionEvents.Began.self) {
            self.onCollisionBegan(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self] else {
            return
        }

        // Reset the win-game triggers when the game starts.
        if gamePlayState == .starting,
           let winGameTriggers = event.entity.scene?.performQuery(query) {
            for winGameTrigger in winGameTriggers {
                winGameTrigger.isEnabled = true
            }
        }
    }

    @MainActor
    func onCollisionBegan (event: CollisionEvents.Began) {
        guard event.entityA.components.has(CharacterMovementComponent.self),
              event.entityB.components.has(WinGameTriggerComponent.self),
              let (gameStateEntity, gameState) = event.entityA.scene?.first(withComponent: GamePlayStateComponent.self),
              gameState.isPlayingGame else {
            return
        }
        event.entityB.isEnabled = false
        event.entityB.components.set(AudioEventComponent(resourceName: "Checkpoint5"))
        gameStateEntity.components.set(GamePlayStateComponent.outroAnimation)
    }
}
