/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the `IntentHandler` and `INCancelWorkoutIntentHandling` protocols to handle requests to cancel the current workout.
*/

import Intents
import AscentFramework

class CancelWorkoutIntentHandler: NSObject, IntentHandler, INCancelWorkoutIntentHandling {

    // MARK: IntentHandler

    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INCancelWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INCancelWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state != .ended {
            response = INCancelWorkoutIntentResponse(code: .ready, userActivity: nil)
        } else {
            response = INCancelWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        completion(response)
    }

    // MARK: Intent handling

    func handle(intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        // `handleInApp` will transfer handling this activity to the main app and deliver the intent to the app delegate in the background.
        let response = INCancelWorkoutIntentResponse(code: .handleInApp, userActivity: nil)
        completion(response)
    }

}
