/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that updates the sunlight rotation.
*/

import RealityKit

public class LightRotationSystem: System {
    public required init(scene: RealityKit.Scene) { }
    
    public func update(context: SceneUpdateContext) {
        let query = EntityQuery(where: .has(LightRotationComponent.self) && .has(TimeOfDayComponent.self))

        for entity in context.entities(matching: query, updatingSystemWhen: .rendering) {
            guard
                let lightRotationComponent = entity.components[LightRotationComponent.self],
                let timeOfDayComponent = entity.components[TimeOfDayComponent.self]
            else { return }

            rotateLightEntities(
                timeOfDay: timeOfDayComponent.timeOfDay,
                entity: entity,
                relativeTo: lightRotationComponent.landmarkEntity
            )
        }
    }
    
    /// Rotates the entity that holds all of the lights to ensure the sun is pointing in the right direction.
   @MainActor func rotateLightEntities(timeOfDay: Float, entity: Entity, relativeTo landmarkEntity: Entity) {
        let tSunrise: Float = 0.2158
        let tNoon: Float = 0.5
        let tSunset: Float = 0.8229
        var angle: Float = 0.0
        if timeOfDay < tSunrise {
            angle = remap(value: timeOfDay, fromMin: 0.0, fromMax: tSunrise, toMin: .pi * 0.5, toMax: .pi)
        } else if timeOfDay < tNoon {
            angle = remap(value: timeOfDay, fromMin: tSunrise, fromMax: tNoon, toMin: .pi, toMax: .pi * 1.5)
        } else if timeOfDay < tSunset {
            angle = remap(value: timeOfDay, fromMin: tNoon, fromMax: tSunset, toMin: .pi * 1.5, toMax: .pi * 2)
        } else {
            angle = remap(value: timeOfDay, fromMin: tSunset, fromMax: 1.0, toMin: .pi * 2, toMax: .pi * 2.5)
        }
        let orientation: simd_quatf = .init(angle: angle, axis: [0, 0, 1])
        entity.setOrientation(orientation, relativeTo: landmarkEntity)
    }
    
    fileprivate func remap(value: Float, fromMin: Float, fromMax: Float, toMin: Float, toMax: Float) -> Float {
        return (value - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin
    }
}
