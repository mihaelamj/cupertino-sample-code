/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A struct that wraps saving and restoring `Workout`s from shared user defaults.
*/

import Foundation

public struct WorkoutHistory {

    var workouts: [Workout]

    public var count: Int {
        return workouts.count
    }

    public subscript(index: Int) -> Workout {
        get {
            return workouts[index]
        }

        set(newValue) {
            workouts[index] = newValue
        }
    }

    public var last: Workout? {
        return workouts.last
    }

    // MARK: Initialization

    private init(workouts: [Workout]) {
        self.workouts = workouts
    }

    // MARK: Load and save

    public static func load() -> WorkoutHistory {
        var workouts = [Workout]()
        let defaults = WorkoutHistory.sharedUserDefaults
        if let savedWorkouts = defaults.object(forKey: "workouts") as? [[String: AnyObject]] {
            for dictionary in savedWorkouts {
                if let workout = Workout(dictionaryRepresentation: dictionary) {
                    workouts.append(workout)
                }
            }
        }

        if workouts.isEmpty {
            let workoutHistory = WorkoutHistory(workouts: sampleWorkouts)
            workoutHistory.save()
            return workoutHistory
        } else {
            return WorkoutHistory(workouts: workouts)
        }
    }

    func save() {
        let workoutDictionaries: [[String: AnyObject]] = workouts.map { $0.dictionaryRepresentation }
        WorkoutHistory.sharedUserDefaults.set(workoutDictionaries as AnyObject, forKey: "workouts")
    }

    // MARK: Convenience

    private static var sharedUserDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.Ascent")
            else { preconditionFailure("Unable to make shared NSUserDefaults object") }
        return defaults
    }

}

extension WorkoutHistory: Sequence {

    public typealias Iterator = AnyIterator<Workout>

    public func makeIterator() -> Iterator {
        var index = 0
        return Iterator {
            guard index < self.workouts.count else { return nil }

            let workout = self.workouts[index]
            index += 1

            return workout
        }
    }

}

extension WorkoutHistory: Equatable {}

/// Extend `WorkoutHistory` with some sample workout data.

public extension WorkoutHistory {

    static var sampleWorkouts: [Workout] {
        // Create three sample workouts so that the history view is never empty.
        return [
            Workout(location: .indoor, obstacle: .wall, goal: .open, state: .ended),
            Workout(location: .indoor, obstacle: .boulder, goal: .timed(1800), state: .ended),
            Workout(location: .outdoor, obstacle: .boulder, goal: .timed(3600), state: .ended)
        ]
    }

}

