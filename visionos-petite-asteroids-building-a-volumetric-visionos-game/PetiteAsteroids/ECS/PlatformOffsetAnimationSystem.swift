/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that animates platforms the character jumps on.
*/

import Combine
import RealityKit
import RealityKitContent
import UIKit

final class PlatformOffsetAnimationSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: PlatformAnimationMarkerComponent.self) {
            self.onDidAddPlatformAnimationMarkerComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidAddPlatformAnimationMarkerComponent(event: ComponentEvents.DidAdd) {
        event.entity.components[CollisionComponent.self]?.filter = CollisionFilter(group: GameSettings.platformAnimationGroup, mask: .all)
    }
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        let entities = context.entities(matching: .init(where: .has(PlatformOffsetAnimationComponent.self)), updatingSystemWhen: .rendering)
        for entity in entities {
            guard let model = entity.components[ModelComponent.self],
                  var platformAnimation = entity.components[PlatformOffsetAnimationComponent.self] else {
                continue
            }
            
            // Record the sign to track when the animation completes.
            let prevSign = sign(platformAnimation.offsetY)
            platformAnimation.offsetY += platformAnimation.velocity * deltaTime
            // Accelerate the opposite velocity (return to `0`).
            platformAnimation.velocity += -1 * prevSign * GameSettings.platformOffsetAnimationSpringBackForce * deltaTime
            let newSign = sign(platformAnimation.offsetY)
            // The animation is complete when the sign changes (no spring movement).
            let isComplete = prevSign != newSign
            if isComplete {
                platformAnimation.offsetY = 0
            }
            
            // Use the platform id and offset to set the shader parameters and animate the platform.
            let platformIndex = Int32(platformAnimation.platformIndex)
            for index in 0..<model.materials.count {
                guard var shaderGraphMaterial = model.materials[index] as? ShaderGraphMaterial else { continue }
                try? shaderGraphMaterial.setParameter(handle: platformAnimation.platformIndexParameterHandle, value: .int(platformIndex))
                try? shaderGraphMaterial.setParameter(handle: platformAnimation.offsetYParameterHandle, value: .float(platformAnimation.offsetY))
                entity.components[ModelComponent.self]?.materials[index] = shaderGraphMaterial
            }
            
            // Remove the component when it's complete; otherwise, update the entity.
            if isComplete {
                entity.components.remove(PlatformOffsetAnimationComponent.self)
            } else {
                entity.components.set(platformAnimation)
            }
        }
    }
    
}
