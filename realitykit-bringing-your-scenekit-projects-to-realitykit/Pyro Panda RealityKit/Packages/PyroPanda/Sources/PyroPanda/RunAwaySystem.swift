/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a RealityKit system so entities run on a path.
*/

import RealityKit

internal class RunAwaySystem: System {
    static let query = EntityQuery(where: .has(RunAwayComponent.self))
    required init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for entity in entities {
            guard let runAwayComponent = entity.components[RunAwayComponent.self]
            else { continue }

            if runAwayComponent.isRunning {
                let pathCurve = runAwayComponent.curve
                var pos = entity.position
                let offsetx = pos.x - sinf(pathCurve * pos.z)

                pos.z += runAwayComponent.speed * Float(context.deltaTime) * 0.5
                pos.x = sinf(pathCurve * pos.z) + offsetx
                entity.position = pos
            }

            ensureNoOverlapForEntity(entity, entities, entityRadius: runAwayComponent.entityRadius)
        }
    }

    @MainActor
    func ensureNoOverlapForEntity(_ entity: Entity, _ entities: QueryResult<Entity>, entityRadius: Float = 0.15) {
        var pos = entity.position

        // Ensure there's no overlapping of entities.
        let pandaRadius: Float = 0.15
        let pandaDiameter = pandaRadius * 2.0
        for ent in entities {
            let otherEntity = ent
            if otherEntity == entity {
                continue
            }

            let otherPos = otherEntity.position
            let vec = otherPos - pos
            let dist = simd_length(vec)
            if dist < pandaDiameter {
                let overlap = pandaDiameter - dist
                pos -= simd_normalize(vec) * overlap
            }
        }

        // The panda friends need to stay within a range in X.
        // This creates a virtual line on the sides so they don't cross the wall or
        // go into the lava.
        pos.x = max(min(pos.x, -4.9), -6.54)
        entity.position = pos
    }

}
