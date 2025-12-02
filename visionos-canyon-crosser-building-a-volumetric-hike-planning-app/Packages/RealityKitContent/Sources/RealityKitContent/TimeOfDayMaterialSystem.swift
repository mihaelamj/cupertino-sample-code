/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system that changes the material colors when light changes during the day.
*/

import RealityKit
import Foundation
import CoreGraphics

public class TimeOfDayMaterialSystem: System {
    static let query = EntityQuery(where: .has(TimeOfDayMaterialComponent.self))
    public required init(scene: RealityKit.Scene) { }
    
    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)

        for entity in entities {
            guard let component = entity.components[TimeOfDayMaterialComponent.self] else {
                return
            }

            apply(entity: entity, timeOfDay: component.timeOfDay, component: component)
            entity.components[TimeOfDayMaterialComponent.self] = component
        }
    }
    
    @MainActor private func apply(entity: Entity, timeOfDay: Float, component: TimeOfDayMaterialComponent) {
        // interpolate the colors for the current time of day
        let fogColorUpper = component.interpolateFogColorUpper(timeOfDay: timeOfDay)
        let fogColorLower = component.interpolateFogColorLower(timeOfDay: timeOfDay)
        let fogColorSide = component.interpolateFogColorSide(timeOfDay: timeOfDay)
        let fogOpacitySide = component.interpolateFogOpacitySide(timeOfDay: timeOfDay)
        let cloudColor = component.interpolateCloudColor(timeOfDay: timeOfDay)
        let overheadCloudBaseColor = component.interpolateOverheadCloudBaseColor(timeOfDay: timeOfDay)
        let overheadCloudEmissiveColor = component.interpolateOverheadCloudEmissiveColor(timeOfDay: timeOfDay)

        entity.setMaterialColorParameters([
            component.fogColorUpperParameterName: fogColorUpper.materialParameter,
            component.fogColorLowerParameterName: fogColorLower.materialParameter,
            component.fogColorSideParameterName: fogColorSide.materialParameter,
            component.fogOpacitySideParameterName: fogOpacitySide.materialParameter,
            component.cloudColorParameterName: cloudColor.materialParameter,
            component.overheadCloudBaseColorParameterName: overheadCloudBaseColor.materialParameter,
            component.overheadCloudEmissiveColorParameterName: overheadCloudEmissiveColor.materialParameter
        ])
        
        // apply recursively!
        entity.children.forEach { child in
            apply(entity: child, timeOfDay: timeOfDay, component: component)
        }
    }
}

public extension Entity {

    func setMaterialColorParameters(_ parameters: [String: MaterialParameters.Value?]) {
        guard var modelComponent = self.components[ModelComponent.self] else {
            // not a model component, so has no materials
            return
        }

        for (name, value) in parameters {
            guard let value = value else { continue }
            for index in modelComponent.materials.indices {
                guard var shaderGraphMaterial = modelComponent.materials[index] as? ShaderGraphMaterial else {
                    // not a shader graph material, so can't set (?)
                    continue
                }
                
                do {
                    try shaderGraphMaterial.setParameter(name: name, value: value)
                    modelComponent.materials[index] = shaderGraphMaterial
                } catch {
                    // print("Failed to set parameter '\(name)' with value '\(value)' on entity '\(self.name)'")
                    continue
                }
            }
        }

        self.components.set(modelComponent)
    }
}

extension Float {
    var materialParameter: MaterialParameters.Value {
        return .float(self)
    }
}

extension SIMD3<Float> {
    var cgColor: CGColor? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
            return nil
        }
        return CGColor(colorSpace: colorSpace, components: [CGFloat(x), CGFloat(y), CGFloat(z), 1.0])
    }
    
    var materialParameter: MaterialParameters.Value? {
        guard let color = cgColor else { return nil }
        return .color(color)
    }
}
