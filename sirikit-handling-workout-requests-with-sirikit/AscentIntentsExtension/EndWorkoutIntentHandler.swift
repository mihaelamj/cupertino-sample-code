/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the `IntentHandler` and `INEndWorkoutIntentHandling` protocols to handle requests to end the current workout.
*/

import Intents
import AscentFramework

class EndWorkoutIntentHandler: NSObject, IntentHandler, INEndWorkoutIntentHandling {

    // MARK: IntentHandler

    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INEndWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(intent endWorkoutIntent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INEndWorkoutIntentResponse

        if workoutHistory.activeWorkout != nil {
            response = INEndWorkoutIntentResponse(code: .ready, userActivity: nil)
        } else {
            response = INEndWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        completion(response)
    }

    // MARK: Intent handling

    func handle(intent endWorkoutIntent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        // `handleInApp` will transfer handling this activity to the main app and deliver the intent to the app delegate in the background.
        let response = INEndWorkoutIntentResponse(code: .handleInApp, userActivity: nil)
        completion(response)
    }

}
