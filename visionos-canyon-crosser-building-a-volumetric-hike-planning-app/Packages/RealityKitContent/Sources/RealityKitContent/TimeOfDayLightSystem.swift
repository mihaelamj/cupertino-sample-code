/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system to change the light colors over the course of the day.
*/

import RealityKit
import Foundation
import CoreGraphics

public class TimeOfDayLightSystem: System {
    static let query = EntityQuery(where: .has(TimeOfDayLightComponent.self))
    public required init(scene: RealityKit.Scene) { }
    
    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)

        for entity in entities {
            guard
                let todLightComponent = entity.components[TimeOfDayLightComponent.self],
                let component = entity.components[TimeOfDayLightComponent.self]
            else {
                return
            }

            let color = todLightComponent.interpolateColor(timeOfDay: component.timeOfDay)
            let intensity = todLightComponent.interpolateIntensity(timeOfDay: component.timeOfDay)
            
            // try to set the color for a directional and spotlight, since we use both.
            entity.setDirectionalLightColor(color: color, intensity: intensity)
            entity.setSpotLightColor(color: color, intensity: intensity)
            
            entity.components[TimeOfDayLightComponent.self] = component
        }
    }
}

public extension Entity {
    func setDirectionalLightColor(color: SIMD3<Float>, intensity: Float) {
        guard var lightComponent = self.components[DirectionalLightComponent.self] else {
            return
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
            return
        }

        guard let newCgColor: CGColor = .init(colorSpace: colorSpace, components: [CGFloat(color.x), CGFloat(color.y), CGFloat(color.z), 1.0]) else {
            return
        }
        let newColor: DirectionalLightComponent.Color = .init(cgColor: newCgColor)
        
        lightComponent.color = newColor
        lightComponent.intensity = intensity
        self.components.set(lightComponent)
    }

    func setSpotLightColor(color: SIMD3<Float>, intensity: Float) {
        guard var lightComponent = self.components[SpotLightComponent.self] else {
            return
        }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
            return
        }

        guard let newCgColor: CGColor = .init(colorSpace: colorSpace, components: [CGFloat(color.x), CGFloat(color.y), CGFloat(color.z), 1.0]) else {
            return
        }
        let newColor: SpotLightComponent.Color = .init(cgColor: newCgColor)

        lightComponent.color = newColor
        lightComponent.intensity = intensity
        self.components.set(lightComponent)
    }
}
