/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that animates and controls visual effects for the character.
*/

import Combine
import SwiftUI
import RealityKit

final class CharacterAnimationSystem: System {
    
    required init(scene: RealityKit.Scene) { }
    
    @MainActor
    func updateEyes(characterAnimationEntity: Entity,
                    characterMovement: CharacterMovementComponent,
                    gameState: GamePlayStateComponent,
                    deltaTime: Float) {
        guard let characterAnimation = characterAnimationEntity.components[CharacterAnimationComponent.self],
              let eyesRotation = characterAnimationEntity.findEntity(named: "EyesRotation") else {
            return
        }
        
        var showEyes = false
        let isAtRest = characterMovement.currentSpeed < 1
        // Only show eyes while resting during or after gameplay.
        if isAtRest, gameState.isBeforeGamePlay == false {
            // Use a timer to track when the eyes need to reappear.
            characterAnimationEntity.components[CharacterAnimationComponent.self]?.eyeAppearTimer -= deltaTime
            if characterAnimation.eyeAppearTimer <= deltaTime {
                showEyes = true
            }
        } else {
            characterAnimationEntity.components[CharacterAnimationComponent.self]?.eyeAppearTimer = GameSettings.eyeAppearDelay
        }
        
        // Make sure the eye rotation entity has an opacity component.
        if eyesRotation.components.has(OpacityComponent.self) == false {
            eyesRotation.components.set(OpacityComponent())
        }
        
        // Hide or show the eyes with an opacity component.
        let eyeOpacity: Float = showEyes ? 1 : 0
        eyesRotation.components[OpacityComponent.self]?.opacity = eyeOpacity
        
        // Always have the eyes face forward relative to the volume.
        let forwardAngle: Float = characterAnimation.volumeViewpoint.angle
        eyesRotation.setOrientation(.init(angle: forwardAngle, axis: [0, 1, 0]), relativeTo: nil)
    }
    
    func update(context: SceneUpdateContext) {
        guard let (gameStateEntity, gameState) = context.scene.first(withComponent: GamePlayStateComponent.self),
              let gameInfo = gameStateEntity.components[GameInfoComponent.self] else { return }
        
        let deltaTime = Float(context.deltaTime)
                
        for characterAnimationEntity in context.entities(matching: .init(where: .has(CharacterAnimationComponent.self)),
                                                         updatingSystemWhen: .rendering) {
            guard let characterAnimation = characterAnimationEntity.components[CharacterAnimationComponent.self],
                  let characterEntity = characterAnimationEntity.scene?.findEntity(id: characterAnimation.characterEntityId),
                  let characterMovement = characterEntity.components[CharacterMovementComponent.self],
                  let characterRotation = characterAnimationEntity.findEntity(named: "CharacterRotation") else {
                continue
            }
            
            // Hide the character when the intro animation is playing.
            if gameState == .introAnimation && gameInfo.isTutorial {
                characterAnimationEntity.components.set(OpacityComponent(opacity: 0))
            } else {
                characterAnimationEntity.components[OpacityComponent.self]?.opacity = 1
            }
            
            // Set the position every frame to match the character entity.
            characterAnimationEntity.setPosition(characterEntity.position(relativeTo: characterAnimationEntity.parent),
                                                 relativeTo: characterAnimationEntity.parent)
            
            // Update the eyes animation.
            updateEyes(
                characterAnimationEntity: characterAnimationEntity,
                characterMovement: characterMovement,
                gameState: gameState,
                deltaTime: deltaTime
            )
            
            // Set the orientation of the character rotation entity to match the orientation of the physics entity.
            characterRotation.setOrientation(characterEntity.orientation(relativeTo: characterAnimationEntity.parent),
                                             relativeTo: characterAnimationEntity.parent)
            
            // Delay the rest of the animation to update at a lower rate.
            characterAnimationEntity.components[CharacterAnimationComponent.self]?.animationTimer -= deltaTime
            if characterAnimation.animationTimer > deltaTime {
                continue
            }
            
            // Reset the animation timer.
            characterAnimationEntity.components[CharacterAnimationComponent.self]?.animationTimer += GameSettings.animationFrameDuration
            
            // Guard to ensure the entity exists and velocity is nonzero.
            guard let (modelEntity, model) = characterRotation.first(withComponent: ModelComponent.self),
                  characterMovement.velocity != .zero else { continue }
            
            // Convert the direction of motion to a direction relative to the model entity.
            let direction = characterAnimationEntity.convert(direction: simd_normalize(characterMovement.velocity), to: modelEntity)
            let intensity = characterMovement.currentSpeed * GameSettings.shearAnimStretchFactor
            for index in 0..<model.materials.count {
                guard var shaderGraphMaterial = model.materials[index] as? ShaderGraphMaterial else { continue }
                
                // Apply the parameters to the shader graph material that the character model uses.
                try? shaderGraphMaterial.setParameter(handle: characterMovement.shearDirectionParameterHandle, value: .simd3Float(direction))
                try? shaderGraphMaterial.setParameter(handle: characterMovement.shearIntensityParameterHandle, value: .float(intensity))
                modelEntity.components[ModelComponent.self]?.materials[index] = shaderGraphMaterial
            }
        }
    }
}
