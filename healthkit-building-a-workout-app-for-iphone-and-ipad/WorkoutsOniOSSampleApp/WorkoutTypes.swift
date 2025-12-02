/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that expand upon multiple workout types.
*/

import Foundation
import HealthKit

struct WorkoutTypes {
    static let supported: [HKWorkoutActivityType] = [
        .walking,
        .running,
        .cycling,
        .rowing,
        .yoga
    ]
    
    static func shouldDisambiguateLocation(for activityType: HKWorkoutActivityType) -> Bool {
        switch activityType {
        case .walking, .running, .cycling, .rowing:
            return true
        default:
            return false
        }
    }
    
    static var workoutConfigurations: [HKWorkoutConfiguration] {
        var configurations: [HKWorkoutConfiguration] = []
        supported.forEach { activityType in
            if shouldDisambiguateLocation(for: activityType) {
                let outdoorConfiguration = HKWorkoutConfiguration()
                outdoorConfiguration.activityType = activityType
                outdoorConfiguration.locationType = .outdoor
                configurations.append(outdoorConfiguration)
                
                let indoorConfiguration = HKWorkoutConfiguration()
                indoorConfiguration.activityType = activityType
                indoorConfiguration.locationType = .indoor
                configurations.append(indoorConfiguration)
            } else {
                let configuration = HKWorkoutConfiguration()
                configuration.activityType = activityType
                configurations.append(configuration)
            }
        }
        return configurations
    }
    
    static func distanceQuantityType(for activityType: HKWorkoutActivityType) -> HKQuantityType? {
        switch activityType {
        case .walking, .running:
            return HKQuantityType(.distanceWalkingRunning)
        case .rowing:
            return HKQuantityType(.distanceRowing)
        case .cycling:
            return HKQuantityType(.distanceCycling)
        default:
            return nil
        }
    }
    
    static func speedQuantityType(for activityType: HKWorkoutActivityType) -> HKQuantityType? {
        switch activityType {
        case .rowing:
            return HKQuantityType(.rowingSpeed)
        default:
            return nil
        }
    }
}

extension HKWorkoutConfiguration {
    
    var name: String {
        if WorkoutTypes.shouldDisambiguateLocation(for: activityType) {
            return "\(locationType) \(activityType.name)"
        } else {
            return activityType.name
        }
    }
    
    var symbol: String {
        switch activityType {
        case .running:
            return locationType == .indoor ? "figure.run.treadmill" : activityType.symbol
        case .walking:
            return locationType == .indoor ? "figure.walk.treadmill" : activityType.symbol
        case .cycling:
            return locationType == .indoor ? "figure.indoor.cycle" : activityType.symbol
        case .rowing:
            return locationType == .indoor ? "figure.indoor.rowing" : activityType.symbol
        default:
            return activityType.symbol
        }
    }
    
    var supportsDistance: Bool {
        if WorkoutTypes.distanceQuantityType(for: activityType) != nil {
            return locationType == .indoor ? false : true
        }
        return false
    }

    var supportsSpeed: Bool {
        if WorkoutTypes.speedQuantityType(for: activityType) != nil {
            return locationType == .indoor ? false : true
        }
        return false
    }
}

extension HKWorkoutActivityType {

    var name: String {
        switch self {
        case .running:
            return "Run"
        case .cycling:
            return "Cycle"
        case .walking:
            return "Walk"
        case .rowing:
            return "Row"
        case .yoga:
            return "Yoga"
        default:
            return ""
        }
    }

    var symbol: String {
        switch self {
        case .running:
            return "figure.run"
        case .cycling:
            return "figure.outdoor.cycle"
        case .walking:
            return "figure.walk"
        case .rowing:
            return "figure.outdoor.rowing"
        case .yoga:
            return "figure.yoga"
        default:
            return "exclamationmark.questionmark"
        }
    }
}

extension HKWorkoutSessionLocationType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .indoor:
            "Indoor"
        case .outdoor:
            "Outdoor"
        case .unknown:
            "Unknown"
        @unknown default:
            fatalError("Unknown HKWorkoutSessionLocationType in \(#function)")
        }
    }
}
