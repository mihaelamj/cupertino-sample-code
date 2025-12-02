/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Scene extensions that support the baked shadow system.
*/

import RealityKit

extension Scene {
    @MainActor
    func applyBakedShadowShaderParameters(parameters: BakedDirectionalLightShadowSystem.ShadowParameters) {
        // Update the shader parameters for each unique receiver individually.
        let uniqueShadowReceivers = self.performQuery(EntityQuery(where: .has(UniqueBakedShadowReceiverComponent.self)))
        for entity in uniqueShadowReceivers {
            guard var shaderGraphMaterial = entity.components[ModelComponent.self]?.materials[0] as? ShaderGraphMaterial,
                  let uniqueShadowReceiver = entity.components[UniqueBakedShadowReceiverComponent.self] else {
                continue
            }
            
            if let worldToShadowMatrix = parameters.worldToShadowMatrix {
                try? shaderGraphMaterial.setParameter(handle: uniqueShadowReceiver.worldToShadowMatrixParameterHandle,
                                                      value: .float4x4(worldToShadowMatrix))
            }
            if let receivesShadows = parameters.receivesShadows {
                try? shaderGraphMaterial.setParameter(handle: uniqueShadowReceiver.receivesShadowsParameterHandle,
                                                      value: .bool(receivesShadows))
            }
            
            entity.components[ModelComponent.self]?.materials[0] = shaderGraphMaterial
        }
        
        // Update the shader parameters for all shared receivers at once.
        let sharedShadowReceivers = self.performQuery( EntityQuery(where: .has(SharedBakedShadowReceiverComponent.self)))
        for entity in sharedShadowReceivers {
            guard let sharedShadowReceiver = entity.components[SharedBakedShadowReceiverComponent.self],
                  var sharedShaderGraphMaterial = entity.components[ModelComponent.self]?.materials[0] as? ShaderGraphMaterial else { continue }
            
            if let worldToShadowMatrix = parameters.worldToShadowMatrix {
                try? sharedShaderGraphMaterial.setParameter(handle: sharedShadowReceiver.worldToShadowMatrixParameterHandle,
                                                            value: .float4x4(worldToShadowMatrix))
            }
            if let receivesShadows = parameters.receivesShadows {
                try? sharedShaderGraphMaterial.setParameter(handle: sharedShadowReceiver.receivesShadowsParameterHandle,
                                                            value: .bool(receivesShadows))
            }
            
            entity.components[ModelComponent.self]?.materials[0] = sharedShaderGraphMaterial
        }
    }
}
