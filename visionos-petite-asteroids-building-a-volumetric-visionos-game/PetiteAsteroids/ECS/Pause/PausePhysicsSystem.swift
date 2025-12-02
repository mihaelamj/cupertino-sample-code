/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the physics simulation clock when the gameplay state pauses the game.
*/

import RealityKit
import Combine
import CoreMedia

final class PausePhysicsSystem: System {
    
    var subscriptions: [AnyCancellable] = []
    
    required init (scene: RealityKit.Scene ) {
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayStateComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayStateComponent (event: ComponentEvents.DidChange) {
        // Guard for the gameplay state and the current scene.
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self], let scene = event.entity.scene else { return }

        if gamePlayState.isPhysicsAllowed {
            scene.playPhysicsSimulation()
        } else {
            scene.pausePhysicsSimulation()
        }
    }
}
