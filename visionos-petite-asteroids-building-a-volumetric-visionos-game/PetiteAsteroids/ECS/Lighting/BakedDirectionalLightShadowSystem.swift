/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that passes the baked directional light shadow information to shader graph materials.
*/

import Combine
import RealityKit
import RealityKitContent

final class BakedDirectionalLightShadowSystem: System {
    struct ShadowParameters {
        var worldToShadowMatrix: float4x4? = nil
        var receivesShadows: Bool? = nil
    }
    
    var subscriptions: [AnyCancellable] = .init()

    init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: RockPickupComponent.self) {
            self.onDidAddRockPickupComponent(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: CharacterAnimationComponent.self) {
            self.onDidAddCharacterAnimationComponent(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self],
              let scene = event.entity.scene else {
            return
        }

        // Disable shadow receivers during the intro animation.
        if gamePlayState == .introAnimation {
            scene.applyBakedShadowShaderParameters(parameters: ShadowParameters(receivesShadows: false))
        }
    }
    
    @MainActor func onDidAddRockPickupComponent(event: ComponentEvents.DidAdd) {
        setShadowReceiversRecursively(entity: event.entity, isUnique: false)
    }
    
    @MainActor func onDidAddCharacterAnimationComponent(event: ComponentEvents.DidAdd) {
        setShadowReceiversRecursively(entity: event.entity, isUnique: true)
    }
    
    @MainActor func setShadowReceiversRecursively(entity: Entity, isUnique: Bool) {
        // Mark the entity as a shadow receiver if it has a shader graph material that takes a world-to-shadow-matrix input.
        if let modelComponent = entity.components[ModelComponent.self],
           let shaderGraphMaterial = modelComponent.materials[0] as? ShaderGraphMaterial,
                  shaderGraphMaterial.parameterNames.contains("WorldToShadowMatrix") {

            if isUnique {
                // Add a shadow receiver component to the entity if it doesn't have one.
                if !entity.components.has(UniqueBakedShadowReceiverComponent.self) {
                    entity.components.set(UniqueBakedShadowReceiverComponent())
                }
            } else {
                // Add a shadow receiver component to the entity if it doesn't have one.
                if !entity.components.has(SharedBakedShadowReceiverComponent.self) {
                    entity.components.set(SharedBakedShadowReceiverComponent())
                }
            }
        }

        for descendent in entity.children {
            setShadowReceiversRecursively(entity: descendent, isUnique: isUnique)
        }
    }

    func update(context: SceneUpdateContext) {
        guard let lightSource = context.first(withComponent: BakedDirectionalLightSourceComponent.self)?.entity else {
            return
        }

        // Get the matrix that converts from world space to shadow map space, and apply it to the scene.
        let worldToShadowMatrix = lightSource.transformMatrix(relativeTo: nil).inverse
        context.scene.applyBakedShadowShaderParameters(parameters: ShadowParameters(worldToShadowMatrix: worldToShadowMatrix))
    }
}
