/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that builds compound-collision components for entities with compound-collision marker components.
*/

import Combine
import RealityKit
import RealityKitContent

final class CompoundCollisionMarkerSystem: System {
    // Store subscriptions in a list.
    var subscriptions: [AnyCancellable] = .init()
    
    required init (scene: Scene ) {
        // Register the `onDidAddCompoundCollisionMarker` callback when adding a custom component to an `Entity`.
        // The callback runs on the scene load.
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: CompoundCollisionMarkerComponent.self) {
            self.onDidAddCompoundCollisionMarker(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidAddCompoundCollisionMarker (event: ComponentEvents.DidAdd) {
        guard let marker = event.entity.components[CompoundCollisionMarkerComponent.self],
              let (levelTrackerEntity, _) = event.entity.firstParent(withComponent: LoadingTrackerComponent.self) else { return }
        
        Task {
            levelTrackerEntity.components[LoadingTrackerComponent.self]?.incrementNumInProgress()
            let (entity, collision) = await event.entity.createCompoundCollision(isStatic: marker.isStatic, deleteModel: marker.deleteModel)
            var physicsBody = PhysicsBodyComponent(shapes: collision.shapes, mass: 1, mode: marker.isStatic ? .static : .dynamic)
            physicsBody.material = .generate(friction: marker.friction, restitution: marker.restitution)
            entity.components.set(physicsBody)
            entity.components[CollisionComponent.self]?.filter = CollisionFilter(group: marker.group.collisionGroup, mask: marker.mask.collisionGroup)
            levelTrackerEntity.components[LoadingTrackerComponent.self]?.decrementNumInProgress()
        }
    }
}
