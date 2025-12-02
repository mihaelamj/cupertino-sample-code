/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the particle system for the intro animation.
*/

import RealityKit
import RealityKitContent

final class IntroParticleAnimationSystem: System {
    
    required init(scene: Scene) { }
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        let entities = context.entities(matching: .init(where: .has(IntroParticleAnimationComponent.self)), updatingSystemWhen: .rendering)
        for entity in entities {
            guard let introParticleAnimation = entity.components[IntroParticleAnimationComponent.self] else { continue }

            // Animate the intro animation particle entity.
            if introParticleAnimation.fadeIn {
                let rate = deltaTime / introParticleAnimation.fadeInTime
                entity.components[ParticleEmitterComponent.self]?.mainEmitter.birthRate += rate * introParticleAnimation.maxValue
                
                entity.components[ParticleEmitterComponent.self]?.speed += rate * (introParticleAnimation.maxSpeed - introParticleAnimation.minSpeed)
                
                entity.components[ParticleEmitterComponent.self]?.speed = max(introParticleAnimation.minSpeed,
                                                                              entity.components[ParticleEmitterComponent.self]?.speed ?? 0)
                
                if entity.components[ParticleEmitterComponent.self]?.mainEmitter.birthRate ?? 0 >= introParticleAnimation.maxValue {
                    entity.components[IntroParticleAnimationComponent.self]?.fadeIn = false
                }
                
                entity.components[SpotLightComponent.self]?.intensity += rate * introParticleAnimation.maxValue
                
                if entity.components[SpotLightComponent.self]?.intensity ?? 0 >= introParticleAnimation.maxValue {
                    entity.components[IntroParticleAnimationComponent.self]?.fadeIn = false
                }
            }
        }
    }
}
