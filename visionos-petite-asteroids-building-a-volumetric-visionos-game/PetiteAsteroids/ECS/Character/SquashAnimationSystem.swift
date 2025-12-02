/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that updates the character's squash animation.
*/

import RealityKit

final class SquashAnimationSystem: System {
    
    required init(scene: Scene) { }
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        let entities = context.entities(matching: .init(where: .has(SquashAnimationComponent.self)), updatingSystemWhen: .rendering)
        for entity in entities {
            guard var squashAnimation = entity.components[SquashAnimationComponent.self] else { continue }
            
            // Count down the animation timer.
            squashAnimation.timer -= deltaTime
            
            if squashAnimation.timer <= 0 {
                // Remove the component and stop the animation when the timer completes.
                entity.components.remove(SquashAnimationComponent.self)
                entity.setScale(.one, relativeTo: entity.parent)
            } else {
                // Animate the squashed entity by interpolating the scale between two values over time.
                let percentComplete = 1 - (squashAnimation.timer / (GameSettings.maxSquashDuration * squashAnimation.multiplier))
                let fromScale = mix(SIMD3<Float>.one, GameSettings.maxSquashScale, t: squashAnimation.multiplier)
                let toScale: SIMD3<Float> = .one
                let scale = mix(fromScale, toScale, t: percentComplete)
                entity.setScale(scale, relativeTo: entity.parent)
                entity.components.set(squashAnimation)
            }
        }
    }
}
