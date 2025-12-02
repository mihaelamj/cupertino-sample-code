/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `GrandCanyonView` to move the sunlight.
*/

import SwiftUI

extension GrandCanyonView {
    
    /// Calculates the time of day based on the progress of the hiker.
    /// - Parameter hikeProgress: The progress of the hiker as a percentage. Defaults to `0` for the default lighting.
    func calculateTimeOfDay(from hikeProgress: Percentage) -> Percentage {
        // Get the departure time as a percentage of the day.
        let departHour = Hours(appModel.hikeTimingComponent.departureDate.hour())
        let departMinutes = Hours(appModel.hikeTimingComponent.departureDate.minutes())
        let departureTime = departHour + (departMinutes / 60.0)
        let hikeDepartPercentage = Percentage(departureTime / 24.0)

        // Get hiking distance in hours.
        let currentHikeDistance: Hours = Hours(Double(hikeProgress) * appModel.hikeTimingComponent.hikeTime / TimeInterval.oneHourInSeconds)

        // Get the percentage of the day that has passed at this point.
        let hikeDistancePercentageOfDay = Percentage(currentHikeDistance / 24.0)
        
        // Get the current time of day based on when the hiker departed and how far they've hiked.
        var currentTimeOfDay = Percentage(hikeDepartPercentage + hikeDistancePercentageOfDay)
        if currentTimeOfDay > 1 {
            // If the time of day moves into the next day, account for this.
            currentTimeOfDay -= 1
        }
        
        return currentTimeOfDay
    }
    
    /// Performs an update to the lighting based on the default start time (7 a.m.).
    func setDefaultSunlight() {
        // Get the default start time (7am) as a percentage of the day.
        let defaultStartTimePercentage = Percentage(Hours(MockData.departureTime.hour()) / 24.0)
        setSunlight(for: defaultStartTimePercentage, shouldAnimateChange: false)
    }
    
    /// Performs an update to the lighting based on the time of day.
    func setSunlight(for targetTimeOfDay: Percentage, shouldAnimateChange: Bool) {
        appModel.root.forEachDescendant(withComponent: TimeOfDayComponent.self) { entity, component in
            guard let component = entity.components[TimeOfDayComponent.self] else {
                return
            }

            entity.components[TimeOfDayComponent.self]?.targetTimeOfDay = targetTimeOfDay
            
            guard shouldAnimateChange else {
                entity.components[TimeOfDayComponent.self]?.timeOfDayChangePerFrame = 1.0
                return
            }
            
            // Animate the difference over 90 frames. The fewer frames, the faster the animation.
            let animationChangePerFrame = abs(component.timeOfDay - targetTimeOfDay) / 90
            
            // Determine the direction to take to the target time.
            let shouldAnimateInPositiveDirection = {
                var difference = targetTimeOfDay - component.timeOfDay
                
                if difference > 0.5 {
                    // If the difference is greater than half, the shorter path is the other way.
                    difference -= 1.0
                } else if difference < -0.5 {
                    // Otherwise, if the difference is less negative half, the shorter path is the other way.
                    difference += 1.0
                }
                
                return difference > 0
            }()
            
            if shouldAnimateInPositiveDirection {
                entity.components[TimeOfDayComponent.self]?.timeOfDayChangePerFrame = animationChangePerFrame
            } else {
                entity.components[TimeOfDayComponent.self]?.timeOfDayChangePerFrame = -animationChangePerFrame
            }
        }
    }
}
