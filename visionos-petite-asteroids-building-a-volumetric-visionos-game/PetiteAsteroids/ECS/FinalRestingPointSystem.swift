/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that removes the model component from entities with final resting-point marker components.
*/

import Combine
import RealityKit
import RealityKitContent

final class FinalRestingPointSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init (scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: FinalRestingPointMarkerComponent.self) {
            self.didAddFinalRestingPointComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func didAddFinalRestingPointComponent (event: ComponentEvents.DidAdd) {
        // Remove the spawn point's model component, if it has one.
        event.entity.components.remove(ModelComponent.self)
    }
}
