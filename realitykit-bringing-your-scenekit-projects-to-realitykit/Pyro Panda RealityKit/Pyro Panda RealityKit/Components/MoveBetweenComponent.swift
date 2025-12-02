/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component and system that repeatedly moves an entity between two points.
*/

import Foundation
import RealityKit

struct MoveBetweenComponent: Component {
    var startPosition: SIMD3<Float>
    var endPosition: SIMD3<Float>
    var duration: TimeInterval
    fileprivate var elapsedTime: TimeInterval = 0
    public init(startPosition: SIMD3<Float>, endPosition: SIMD3<Float>, duration: TimeInterval) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.duration = duration
        MoveBetweenSystem.registerSystem()
    }

    private static let twoPi: TimeInterval = { 2 * TimeInterval(Float.pi) }()

    fileprivate var tPosition: Float {
        Float(cos(elapsedTime * Self.twoPi / duration) + 1) / 2
    }
}

struct MoveBetweenSystem: System {
    init(scene: Scene) {}

    static let query = EntityQuery(where: .has(MoveBetweenComponent.self))

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var moveBetweenComponent = entity.components[MoveBetweenComponent.self]
            else { continue }
            moveBetweenComponent.elapsedTime += context.deltaTime
            entity.position = mix(
                moveBetweenComponent.startPosition,
                moveBetweenComponent.endPosition,
                t: moveBetweenComponent.tPosition
            )
            entity.components.set(moveBetweenComponent)
        }
    }
}
