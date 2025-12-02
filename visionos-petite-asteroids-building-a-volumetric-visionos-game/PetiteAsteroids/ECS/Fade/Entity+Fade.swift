/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for an entity that animate its opacity.
*/

import RealityKit
import RealityKitContent

extension Entity {
    func setFadeAmount(fadeAmount: Float) {
        guard let fader = self.components[FaderComponent.self] else { return }
        
        // Iterate through each fade material on this model and apply the fade shader parameters.
        if var modelComponent = self.components[ModelComponent.self],
           let materialIndices = fader.materialIndices {
            for materialIndex in materialIndices {
                guard var shaderGraphMaterial = modelComponent.materials[materialIndex] as? ShaderGraphMaterial else {
                    continue
                }
                
                try? shaderGraphMaterial.setParameter(handle: fader.fadeMixAmountParameterHandle, value: .float(fadeAmount))
                
                modelComponent.materials[materialIndex] = shaderGraphMaterial
            }
            self.components.set(modelComponent)
        }
        // Apply the fade to the entity's opacity component, if it has one.
        if self.components.has(OpacityFaderComponent.self) {
            self.components[OpacityComponent.self]?.opacity = 1 - fadeAmount
        }
        // Apply the fade to the intensity of the entity's directional light component, if it has one.
        if let intensity = self.components[DirectionalLightFaderComponent.self]?.intensity {
            self.components[DirectionalLightComponent.self]?.intensity = (1 - fadeAmount) * intensity
        }
        // Apply the fade to the blend of the entity's image-based light component, if it has one.
        if self.components.has(IBLFaderComponent.self),
           let iblSource = self.components[ImageBasedLightComponent.self]?.source {
            switch iblSource {
                case .blend(let environmentResourceA, let environmentResourceB, _):
                    self.components[ImageBasedLightComponent.self]?.source = .blend(environmentResourceA, environmentResourceB, fadeAmount)
                default:
                    break
            }
        }
    }
    
    func setFadeAmountForDescendants(fadeAmount: Float) {
        self.forEachDescendant(withComponent: FaderComponent.self) { entity, _ in
            entity.setFadeAmount(fadeAmount: fadeAmount)
        }
    }
    
    func playFadeAnimationOnDescendants(fadeType: FadeType, duration: Float, timingFunction: EasingFunction) {
        self.forEachDescendant(withComponent: FaderComponent.self) { entity, faderComponent in
            entity.components[FaderComponent.self]?.fadeTime = 0
            entity.components[FaderComponent.self]?.fadeType = fadeType
            entity.components[FaderComponent.self]?.fadeDuration = duration
            entity.components[FaderComponent.self]?.timingFunction = timingFunction
            entity.components[FaderComponent.self]?.isFading = true
        }
    }
}
