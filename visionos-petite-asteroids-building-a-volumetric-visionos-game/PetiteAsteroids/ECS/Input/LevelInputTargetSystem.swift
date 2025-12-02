/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that adds input target components to entities with level input target components.
*/

import RealityKit
import RealityKitContent
import Combine

final class LevelInputTargetSystem: System {
    var subscriptions: [AnyCancellable] = .init()
    
    init (scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: LevelInputTargetComponent.self) {
            self.didAddLevelInputTarget(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func didAddLevelInputTarget(event: ComponentEvents.DidAdd) {
        event.entity.components.set(InputTargetComponent())
        event.entity.forEachDescendant { descendant in
            if !descendant.components.has(InputTargetComponent.self) {
                var inputTargetComponent = InputTargetComponent()
                inputTargetComponent.isEnabled = false
                descendant.components.set(inputTargetComponent)
            }
        }
    }
}
