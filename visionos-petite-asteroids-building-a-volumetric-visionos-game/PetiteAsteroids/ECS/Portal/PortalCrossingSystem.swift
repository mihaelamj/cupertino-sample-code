/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that adds portal crossing components to entities with portal crossing marker components.
*/

import RealityKit
import RealityKitContent
import Combine

struct PortalCrossingSystem: System {
    var subscriptions: [AnyCancellable] = .init()
    
    init (scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: PortalCrossingMarkerComponent.self) { event in
            event.entity.components.set(PortalCrossingComponent())
        }.store(in: &subscriptions)
    }
}
