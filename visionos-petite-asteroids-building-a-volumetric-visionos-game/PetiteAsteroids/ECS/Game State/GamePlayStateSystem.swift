/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that updates state data for various components as the gameplay state changes.
*/

import Combine
import RealityKit
import Foundation

final class GamePlayStateSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self] else { return }
        
        switch gamePlayState {
            case .starting:
                // Ensure the level isn't faded to black if the player restarts after the postgame where the level faded to black.
                event.entity.setFadeAmountForDescendants(fadeAmount: 0)
            default:
                break
        }
    }
    
    func update(context: SceneUpdateContext) {
        for gamePlayStateEntity in context.entities(matching: EntityQuery(where: .has(GamePlayStateComponent.self)), updatingSystemWhen: .rendering) {
            
            // Guard for the gameplay state and verify the loading tracker completes.
            guard let gamePlayState = gamePlayStateEntity.components[GamePlayStateComponent.self],
                  let loadingTracker = gamePlayStateEntity.components[LoadingTrackerComponent.self],
                  loadingTracker.isComplete() else { return }
            
            if gamePlayState == .starting {
                // Immediately enter the playing state when detecting the staring state.
                gamePlayStateEntity.components.set(GamePlayStateComponent.playing(isPaused: false))
            }
        }
    }
}
