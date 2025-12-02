/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration representing the different types of activities people can enjoy doing on a trail.
*/

import AppIntents
import Foundation
import HealthKit

enum ActivityStyle: String, Codable, Sendable {
    case biking
    case equestrian
    case hiking
    case jogging
    case crossCountrySkiing
    case snowshoeing
    
    /// The string name for an SF Symbols symbol representing the value.
    var symbol: String {
        switch self {
        case .biking:
            return "figure.outdoor.cycle"
        case .equestrian:
            return "figure.equestrian.sports"
        case .hiking:
            return "figure.hiking"
        case .jogging:
            return "figure.run"
        case .crossCountrySkiing:
            return "figure.skiing.crosscountry"
        case .snowshoeing:
            return "snowflake"
        }
    }

    /// The HealthKit workout type that corresponds to the activity type.
    var workoutStyle: HKWorkoutActivityType {
        switch self {
        case .biking:
            return .cycling
        case .equestrian:
            return .equestrianSports
        case .hiking:
            return .hiking
        case .jogging:
            return .running
        case .crossCountrySkiing:
            return .crossCountrySkiing
        case .snowshoeing:
            return .snowSports
        }
    }
}

/// Conforming `ActivityStyle` to `AppEnum` makes it available for use as a parameter in an `AppIntent`.
extension ActivityStyle: AppEnum {
    
    /**
     A localized name representing this entity as a concept people are familiar with in the app, including localized variations based on the plural
     rules the app defines in `AppIntents.stringsdict` which the app references here through the `table` parameter. The system may show
     this value to people when they configure an intent.
     */
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Activity", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) activities", table: "AppIntents")
        )
    }
    
    /// Localized names for each case that the enumeration defines. The system shows these values to people when they configure or use an intent.
    static let caseDisplayRepresentations: [ActivityStyle: DisplayRepresentation] = [
        .biking: DisplayRepresentation(title: "Biking",
                                       subtitle: "Mountain bike ride",
                                       image: .init(systemName: "figure.outdoor.cycle")),
        
        .equestrian: DisplayRepresentation(title: "Equestrian",
                                           subtitle: "Equestrian sports",
                                           image: .init(systemName: "figure.equestrian.sports")),
        
        .hiking: DisplayRepresentation(title: "Hiking",
                                       subtitle: "A lengthy outdoor walk",
                                       image: .init(systemName: "figure.hiking")),
        
        .jogging: DisplayRepresentation(title: "Jogging",
                                        subtitle: "A gentle run",
                                        image: .init(systemName: "figure.run")),
        
        .crossCountrySkiing: DisplayRepresentation(title: "Skiing",
                                                   subtitle: "Cross-country skiing",
                                                   image: .init(systemName: "figure.skiing.crosscountry")),
        
        .snowshoeing: DisplayRepresentation(title: "Snowshoeing",
                                            subtitle: "Walking in the snow",
                                            image: .init(systemName: "snowflake"))
    ]
}

extension Array where Element == ActivityStyle {
    
    /// Transforms the activities in the array into an array of localized strings.
    var localizedElements: [String] {
        let activities: [String] = compactMap { activity in
            guard let activityName = ActivityStyle.caseDisplayRepresentations[activity] else {
                return nil
            }
            return String(localized: activityName.title)
        }
        return activities
    }
    
    /// Flattens an array of activities to a formatted string.
    var formattedDisplayValue: String {
        return localizedElements.joined(separator: ", ")
    }
}
