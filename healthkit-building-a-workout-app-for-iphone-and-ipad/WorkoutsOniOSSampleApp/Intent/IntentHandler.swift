/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Types that conform to the `IntentHandler` protocol that you query to determine whether they can handle a specific type of `INIntent`.
*/

import Intents
import SwiftUI
import HealthKit

public class IntentHandler: INExtension {
    
}

extension IntentHandler: INStartWorkoutIntentHandling {
    
    public func handle(intent: INStartWorkoutIntent) async -> INStartWorkoutIntentResponse {
        let state = await WorkoutManager.shared.state
        
        switch state {
        case .running, .paused, .prepared, .stopped:
            return INStartWorkoutIntentResponse(code: .failureOngoingWorkout, userActivity: nil)
        default:
            break
        }
        
        Task {
            await MainActor.run {
                // Handle the intent's activity type and location.
                WorkoutManager.shared.setWorkoutConfiguration(activityType: .running, location: .outdoor)
            }
        }
        return INStartWorkoutIntentResponse(code: .success, userActivity: nil)
    }
}

extension IntentHandler: INPauseWorkoutIntentHandling {
    
    public func handle(intent: INPauseWorkoutIntent) async -> INPauseWorkoutIntentResponse {
        let state = await WorkoutManager.shared.state
        if state != .running {
            return INPauseWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        Task {
            await MainActor.run {
                WorkoutManager.shared.pause()
            }
        }
        return INPauseWorkoutIntentResponse(code: .success, userActivity: nil)
    }
}

extension IntentHandler: INResumeWorkoutIntentHandling {
    public func handle(intent: INResumeWorkoutIntent) async -> INResumeWorkoutIntentResponse {
        let state = await WorkoutManager.shared.state
        
        if state != .paused {
            return INResumeWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        Task {
            await MainActor.run {
                WorkoutManager.shared.resume()
            }
        }
        return INResumeWorkoutIntentResponse(code: .success, userActivity: nil)
    }
}

extension IntentHandler: INEndWorkoutIntentHandling {
    
    public func handle(intent: INEndWorkoutIntent) async -> INEndWorkoutIntentResponse {
        let state = await WorkoutManager.shared.state
        
        switch state {
        case .notStarted, .ended:
            return INEndWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        default:
            Task {
                await MainActor.run {
                    WorkoutManager.shared.endWorkout()
                }
            }
            return INEndWorkoutIntentResponse(code: .success, userActivity: nil)
        }
    }
    
}
    
