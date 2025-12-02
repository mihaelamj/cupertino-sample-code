/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that supports fading materials, opacity components, the intensity of directional light components,
 and the blend parameter of image-based light components.
*/

import Combine
import RealityKit
import RealityKitContent

class FaderSystem: System {
    let query = EntityQuery(where: .has(FaderComponent.self))
    
    var subscriptions: [AnyCancellable] = .init()
    required init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: ModelFaderMarkerComponent.self) {
            self.onDidAddModelFaderMarker(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: OpacityFaderComponent.self) {
            self.onDidAddOpacityFader(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: DirectionalLightFaderComponent.self) {
            self.onDidAddDirectionalLightFader(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: IBLFaderComponent.self) {
            self.onDidAddIBLFader(event: $0)
        }.store(in: &subscriptions)
    }

    @MainActor
    func onDidAddModelFaderMarker(event: ComponentEvents.DidAdd) {
        setModelFadersRecursively(entity: event.entity)
    }
    
    @MainActor
    func onDidAddOpacityFader(event: ComponentEvents.DidAdd) {
        event.entity.components.set(FaderComponent())
        if !event.entity.components.has(OpacityComponent.self) {
            event.entity.components.set(OpacityComponent())
        }
    }
    
    @MainActor
    func onDidAddDirectionalLightFader(event: ComponentEvents.DidAdd) {
        event.entity.components.set(FaderComponent())
    }
    
    @MainActor
    func onDidAddIBLFader(event: ComponentEvents.DidAdd) {
        event.entity.components.set(FaderComponent())
    }

    @MainActor
    func setModelFadersRecursively(entity: Entity) {
        if let modelComponent = entity.components[ModelComponent.self] {
            
            // Get the fader component for the entity, or create one if none exists.
            var fader = entity.components[FaderComponent.self] ?? FaderComponent(materialIndices: Set<Int>())
            
            for (index, material) in modelComponent.materials.enumerated() {
                // Skip the material if it's not a shader graph material that takes a fade mix amount input.
                guard var shaderGraphMaterial = material as? ShaderGraphMaterial,
                      shaderGraphMaterial.parameterNames.contains("FadeMixAmount") else { continue }

                // Set the initial shader parameters.
                try? shaderGraphMaterial.setParameter(handle: fader.fadeMixAmountParameterHandle, value: .float(0))
                try? shaderGraphMaterial.setParameter(handle: fader.fadeColorBottomParameterHandle, value: .color(GameSettings.fadeColorBottom))
                try? shaderGraphMaterial.setParameter(handle: fader.fadeColorTopParameterHandle, value: .color(GameSettings.fadeColorTop))
                try? shaderGraphMaterial.setParameter(handle: fader.gradientGammaParameterHandle, value: .float(GameSettings.gradientGamma))
                try? shaderGraphMaterial.setParameter(handle: fader.gradientStartYParameterHandle, value: .float(GameSettings.gradientStartY))
                try? shaderGraphMaterial.setParameter(handle: fader.gradientEndYParameterHandle, value: .float(GameSettings.gradientEndY))
                entity.components[ModelComponent.self]?.materials[index] = shaderGraphMaterial

                // Store the material index of the fade shader.
                fader.materialIndices?.insert(index)
                
                // Set the fader component on the entity.
                entity.components.set(fader)
            }
        }

        for child in entity.children {
            setModelFadersRecursively(entity: child)
        }
    }
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: query, updatingSystemWhen: .rendering) {
            if var faderComponent = entity.components[FaderComponent.self],
               faderComponent.isFading {
                
                // Update the fade mix amount.
                faderComponent.fadeTime += Float(context.deltaTime) / faderComponent.fadeDuration
                let timing = faderComponent.timingFunction.evaluate(faderComponent.fadeTime)
                faderComponent.fadeMixAmount = faderComponent.fadeType == .fadeOut ? timing : 1 - timing
                // Stop the fade when it's complete.
                if faderComponent.fadeTime >= 1 {
                    faderComponent.fadeMixAmount = clamp01(faderComponent.fadeMixAmount)
                    faderComponent.isFading = false
                }
                
                // Apply changes by setting the components.
                entity.components.set(faderComponent)
                
                // Apply the fade effect to the entity.
                entity.setFadeAmount(fadeAmount: faderComponent.fadeMixAmount)
            }
        }
    }
}
