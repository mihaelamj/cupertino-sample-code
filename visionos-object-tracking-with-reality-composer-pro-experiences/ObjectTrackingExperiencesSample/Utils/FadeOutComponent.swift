/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that manages fading out of a target entity.
*/
import Foundation
import Combine
import RealityKit

/// A component that gradually reduces the opacity of the target entity over a specified duration, that provides a smooth fade-out effect.
struct FadeOutComponent: Component {
    var duration: Float
    var currentProgress: Float = 0.0
    var initialOpacity: Float = 1.0
    var completionHandler: (() -> Void)?
    var isFading: Bool = false
}

@MainActor
class FadeOutSystem: System {
    private static let query = EntityQuery(where: .has(FadeOutComponent.self))
    
    required init(scene: Scene) { }
        
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            updateAnimation(on: entity, deltaTime: context.deltaTime)
        }
    }
    
    private func updateAnimation(on entity: Entity, deltaTime: TimeInterval) {
        guard var fadeOutComponent = entity.components[FadeOutComponent.self], fadeOutComponent.isFading else { return }
        fadeOutComponent.currentProgress += Float(deltaTime)
        let progressRatio = fadeOutComponent.currentProgress / fadeOutComponent.duration
        let newOpacity = fadeOutComponent.initialOpacity * (1 - progressRatio)
        entity.components.set(OpacityComponent(opacity: newOpacity))
        if fadeOutComponent.currentProgress >= fadeOutComponent.duration {
            fadeOutComponent.isFading = false
            fadeOutComponent.completionHandler?()
        }
        entity.components.set(fadeOutComponent)
    }
}
