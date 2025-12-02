/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides the workout configuration for a workout.
*/

import HealthKit

extension HKWorkout {
    var workoutConfiguration: HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutActivityType
        if let isIndoorWorkout = self.metadata![HKMetadataKeyIndoorWorkout] as? Bool,
            isIndoorWorkout {
                configuration.locationType = .indoor
        } else {
                configuration.locationType = .outdoor
        }
        return configuration
    }
}
