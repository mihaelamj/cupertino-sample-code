/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system used rotate entities.
*/
import RealityKit
import simd

/// A system that rotates entities with a rotation component.
public struct RotationSystem: System {
    static let rotationQuery = EntityQuery(where: .has(RotationComponent.self))

    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        /// Find entities with a `RotationComponent`.
        let entities = context.entities(matching: Self.rotationQuery, updatingSystemWhen: .rendering)
        for entity in entities {
            /// Ensure the component is found.
            guard let component = entity.components[RotationComponent.self] else { continue }
            /// If the entity has a zero speed ignore it.
            if component.speed == 0.0 { continue }
            /// Set the orientation of the entity relative to itself, based on
            /// the speed and change in the time base.
            entity.setOrientation(simd_quatf(angle: component.speed * Float(context.deltaTime),
                                             axis: component.axis),
                                  relativeTo: entity)
        }
    }
}
