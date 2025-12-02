/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a RealityKit system to spin entities.
*/

import RealityKit

internal class SpinSystem: System {
    static let query = EntityQuery(where: .has(SpinComponent.self))
    required init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for entity in entities {
            guard let spinComponent = entity.components[SpinComponent.self]
            else { continue }

            let angleSpeed = spinComponent.rotationsPerSecond * .pi * 2
            entity.orientation *= simd_quatf(
                angle: Float(context.deltaTime) * angleSpeed, axis: spinComponent.axis
            )
        }
    }
}
