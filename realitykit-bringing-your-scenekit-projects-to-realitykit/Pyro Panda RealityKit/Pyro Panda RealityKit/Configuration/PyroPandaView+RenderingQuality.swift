/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Enables and disables features based on the GPU family.
*/
import SwiftUI
import RealityKit

@available(visionOS, unavailable)
@available(macOS, introduced: 26.0)
@available(iOS, introduced: 26.0)
@available(tvOS, introduced: 26.0)
extension PyroPandaView {
    func adjustRenderingQuality(_ content: inout RealityViewCameraContent, _ gameRoot: Entity) {
        gameRoot.recursiveCall(self.turnOffNormalMaps)
        if let gameLight = gameRoot.findEntity(named: "DirectionalLight") {
            gameLight.recursiveCall(self.turnOffSoftShadows)
        }
        turnOffParticles(from: gameRoot)
        turnOffPostProcess(content: &content)
        gameRoot.recursiveCall(self.turnOffVertexShaderModifiers)
        gameRoot.recursiveCall(self.turnOffVegetation)
    }

    fileprivate func turnOffOverlays() {
        appModel.displayOverlaysVisible = false
    }

    fileprivate func turnOffNormalMaps(from entity: Entity) {
        if var modelComponent = entity.components[ModelComponent.self] {
            // Modify the material property `normalsOn`, if it exists.
            let newMaterials: [any RealityKit.Material] = modelComponent
                .materials.map { material in
                    if var shaderMaterial = material as? ShaderGraphMaterial,
                       shaderMaterial.parameterNames.contains("normalsOn") {
                        try? shaderMaterial.setParameter(name: "normalsOn", value: .bool(false))
                        return shaderMaterial
                    } else {
                        return material
                    }
                }

            // Update the model component with modified materials.
            modelComponent.materials = newMaterials
            entity.components.set(modelComponent)
        }
    }

    fileprivate func turnOffSoftShadows(from entity: Entity) {
        entity.components.remove(DirectionalLightComponent.Shadow.self)
    }
    
    fileprivate func turnOffParticles(from entity: Entity) {
        entity.components.remove(ParticleEmitterComponent.self)

        // Recursively call this function on all subentities.
        for child in entity.children {
            // Except for Max and the door.
            if child.name == "Max" || child.name == "unlock_door" {
                continue
            }
            turnOffParticles(from: child)
        }
    }
    
    fileprivate func turnOffPostProcess(content: inout RealityViewCameraContent) {
        content.renderingEffects.antialiasing = .none
        content.renderingEffects.cameraGrain = .disabled
        content.renderingEffects.motionBlur = .disabled
        content.renderingEffects.depthOfField = .disabled
        content.renderingEffects.customPostProcessing = .none
    }

    fileprivate func turnOffVertexShaderModifiers(from entity: Entity) {
        if var modelComponent = entity.components[ModelComponent.self] {
            var newMaterials: [RealityKit.Material] = []

            for material in modelComponent.materials {
                if var shaderMaterial = material as? ShaderGraphMaterial {
                    try? shaderMaterial.setParameter(name: "vertexShaderOn", value: .bool(false))
                    newMaterials.append(shaderMaterial)
                } else {
                    newMaterials.append(material)
                }
            }

            // Update the model component with modified materials.
            modelComponent.materials = newMaterials
            entity.components.set(modelComponent)
        }
    }

    fileprivate func turnOffVegetation(from entity: Entity) {
        if let modelComponent = entity.components[ModelComponent.self] {
            for material in modelComponent.materials {
                guard let name = material.name else { continue }
                if name.hasPrefix("vegetation_") {
                    entity.isEnabled = false
                    break
                }
            }
        }
    }
}
