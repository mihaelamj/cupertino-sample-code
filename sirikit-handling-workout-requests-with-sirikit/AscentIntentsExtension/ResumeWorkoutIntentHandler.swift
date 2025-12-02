/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the `IntentHandler` and `INResumeWorkoutIntentHandling` protocols to handle requests to resume the current workout.
*/

import Intents
import AscentFramework

class ResumeWorkoutIntentHandler: NSObject, IntentHandler, INResumeWorkoutIntentHandling {

    // MARK: IntentHandler

    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INResumeWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(intent resumeWorkoutIntent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INResumeWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state == .paused {
            response = INResumeWorkoutIntentResponse(code: .ready, userActivity: nil)
        } else {
            response = INResumeWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        completion(response)
    }

    // MARK: Intent handling

    func handle(intent resumeWorkoutIntent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        // `handleInApp` will transfer handling this activity to the main app and deliver the intent to the app delegate in the background.
        let response = INResumeWorkoutIntentResponse(code: .handleInApp, userActivity: nil)
        completion(response)
    }

}
