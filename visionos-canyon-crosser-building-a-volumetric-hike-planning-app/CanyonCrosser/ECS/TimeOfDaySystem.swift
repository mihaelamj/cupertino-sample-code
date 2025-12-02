/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system to animate the sunlight to the set time of day.
*/

import RealityKit
import RealityKitContent
import Foundation

class TimeOfDaySystem: System {
    public required init(scene: RealityKit.Scene) { }

    public func update(context: SceneUpdateContext) {
        let query = EntityQuery(where: .has(TimeOfDayComponent.self))

        for entity in context.entities(matching: query, updatingSystemWhen: .rendering) {
            guard let timeOfDayComponent = entity.components[TimeOfDayComponent.self] else {
                return
            }

            let timeOfDay = calculateTimeOfDay(from: timeOfDayComponent, deltaTime: context.deltaTime)

            entity.components[TimeOfDayComponent.self]?.timeOfDay = timeOfDay
            entity.components[TimeOfDayLightComponent.self]?.timeOfDay = timeOfDay
            entity.components[TimeOfDayMaterialComponent.self]?.timeOfDay = timeOfDay
        }
    }

    private func calculateTimeOfDay(from component: TimeOfDayComponent, deltaTime: TimeInterval) -> Float {
        guard
            component.timeOfDayChangePerFrame < 1.0,
            component.timeOfDay != component.targetTimeOfDay
        else {
            return component.targetTimeOfDay
        }

        var timeOfDay = component.timeOfDay

        if component.timeOfDayChangePerFrame > 0 {
            // When the change amount is positive, add up to the difference to the target value.
            timeOfDay += min(component.timeOfDayChangePerFrame, abs(component.targetTimeOfDay - timeOfDay))
        } else {
            // When the change amount is negative, subtract up to the difference to the target value.
            timeOfDay -= min(abs(component.timeOfDayChangePerFrame), abs(component.targetTimeOfDay - timeOfDay))
        }

        if timeOfDay < 0.0 {
            // Reset `timeOfDay` back to `1.0`, when `timeOfDay` goes past `0.0`.
            timeOfDay += 1.0
        } else if timeOfDay > 1.0 {
            // Reset `timeOfDay` back to `0.0`, when `timeOfDay` goes past `1.0`.
            timeOfDay -= 1.0
        }

        return timeOfDay
    }
}
