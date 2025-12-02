/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A summary of activity statistics, including distance traveled and calories burned.
*/

import AppIntents
import Foundation

/**
 A `TransientAppEntity` represents data that an `EntityQuery` can't query because the data continually changes, such as a summary
 of workout statistics. This type of app entity is helpful for returning data from an intent so that other intents can use its properties as inputs
 to other intents, enabling powerful workflows in the Shortcuts app.
 */
struct ActivityStatisticsSummary: TransientAppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Workout Summary")
    
    @Property var summaryStartDate: Date
    @Property var workoutsCompleted: Int
    @Property var caloriesBurned: Measurement<UnitEnergy>
    @Property var distanceTraveled: Measurement<UnitLength>
    
    init() {
        summaryStartDate = Date()
        workoutsCompleted = 0
        caloriesBurned = Measurement(value: 0, unit: .calories)
        distanceTraveled = Measurement(value: 0, unit: .meters)
    }
    
    var displayRepresentation: DisplayRepresentation {
        var image = "party.popper"
        var subtitle = LocalizedStringResource(
            "You burned \(caloriesBurned.formatted(.measurement(width: .abbreviated, usage: .food))) calories.")
        
        if workoutsCompleted == 0 {
            image = "figure.hiking"
            subtitle = LocalizedStringResource("You haven't logged a workout yet.")
        }
        
        return DisplayRepresentation(title: "Workout Summary",
                                     subtitle: subtitle,
                                     image: DisplayRepresentation.Image(systemName: image),
                                     synonyms: ["Activity Summary"])
    }
}
