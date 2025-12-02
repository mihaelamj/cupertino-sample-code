/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that manages the position of the character's spawn point.
*/

import Combine
import RealityKit
import RealityKitContent

final class CharacterSpawnPointSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init (scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: CharacterSpawnPointComponent.self) {
            self.didAddCharacterSpawnPointComponent(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func didAddCharacterSpawnPointComponent(event: ComponentEvents.DidAdd) {
        // Remove the spawn point's model component, if it has one.
        event.entity.components.remove(ModelComponent.self)
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        guard event.entity.components[GamePlayStateComponent.self]?.isBeforeGamePlay == true,
              let spawnPointEntity = event.entity.scene?.first(withComponent: CharacterSpawnPointComponent.self)?.entity else { return }
        
        // Reset the spawn point entity relative to its root entity.
        spawnPointEntity.setPosition(.zero, relativeTo: spawnPointEntity.parent)
    }
}
