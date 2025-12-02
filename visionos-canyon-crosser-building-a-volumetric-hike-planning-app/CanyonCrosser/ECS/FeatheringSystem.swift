/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system to set the shader to fade the clouds in and out of the volume when clipped.
*/

import RealityKit
import SwiftUI

struct FadingCloudComponent: Component {}

struct FeatheringSystem: System {
    static let query = EntityQuery(where: .has(FadingCloudComponent.self) && .has(ClippingMarginPercentageComponent.self))

    init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.scene.performQuery(Self.query) {
            guard
                let clippingMarginPercentageComponent = entity.components[ClippingMarginPercentageComponent.self],
                var modelComponent = entity.components[ModelComponent.self],
                let material = modelComponent.materials.first,
                var shaderGraphMaterial = material as? ShaderGraphMaterial
            else {
                return
            }
            shaderGraphMaterial.set(name: "topEdgeInset", value: .float(abs(clippingMarginPercentageComponent.environment.clippingMargins.max.y)))
            shaderGraphMaterial.set(name: "leadingEdgeInset", value: .float(abs(clippingMarginPercentageComponent.environment.clippingMargins.min.x)))
            shaderGraphMaterial.set(name: "trailingEdgeInset", value: .float(abs(clippingMarginPercentageComponent.environment.clippingMargins.max.x)))
            shaderGraphMaterial.set(name: "bottomEdgeInset", value: .float(abs(clippingMarginPercentageComponent.environment.clippingMargins.min.y)))
            shaderGraphMaterial.set(name: "backEdgeInset", value: .float(abs(clippingMarginPercentageComponent.environment.clippingMargins.min.z)))
            shaderGraphMaterial.set(name: "minContentBounds", value: .simd3Float(clippingMarginPercentageComponent.environment.contentViewBounds.min))
            shaderGraphMaterial.set(name: "maxContentBounds", value: .simd3Float(clippingMarginPercentageComponent.environment.contentViewBounds.max))
            shaderGraphMaterial.set(name: "sceneViewCenter", value: .simd3Float(clippingMarginPercentageComponent.environment.sceneViewBounds.center))

            modelComponent.materials = [shaderGraphMaterial]
            entity.components[ModelComponent.self] = modelComponent
        }
    }
}

extension ShaderGraphMaterial {
    fileprivate mutating func set(name: String, value newValue: MaterialParameters.Value) {
        do {
            try setParameter(name: name, value: newValue)
        } catch {
            print("Failed to set \(name) on shader graph material: \(error)")
        }
    }
}
