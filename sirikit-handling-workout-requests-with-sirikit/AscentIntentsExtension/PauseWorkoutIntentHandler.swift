/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the `IntentHandler` and `INPauseWorkoutIntentHandling` protocols to handle requests to pause the current workout.
*/

import Intents
import AscentFramework

class PauseWorkoutIntentHandler: NSObject, IntentHandler, INPauseWorkoutIntentHandling {

    // MARK: IntentHandler

    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INPauseWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(intent pauseWorkoutIntent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INPauseWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state == .active {
            response = INPauseWorkoutIntentResponse(code: .ready, userActivity: nil)
        } else {
            response = INPauseWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        completion(response)
    }

    // MARK: Intent handling

    func handle(intent pauseWorkoutIntent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        // `handleInApp` will transfer handling this activity to the main app and deliver the intent to the app delegate in the background.
        let response = INPauseWorkoutIntentResponse(code: .handleInApp, userActivity: nil)
        completion(response)
    }

}
