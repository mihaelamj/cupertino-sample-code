/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that implements the `IntentHandler` and `INStartWorkoutIntentHandling` protocols to handle requests to start a new workout.
*/

import Intents
import AscentFramework

class StartWorkoutIntentHandler: NSObject, IntentHandler, INStartWorkoutIntentHandling {

    var isOpenEnded: Bool = false

    // MARK: IntentHandler

    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INStartWorkoutIntent
    }

    // MARK: Parameter resolution

    /// - Tag: ResolveWorkoutName
    func resolveWorkoutName(for intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        let result: INSpeakableStringResolutionResult
        let workoutHistory = WorkoutHistory.load()

        if let name = intent.workoutName {
            // Try to determine the obstacle (wall or boulder) from the supplied workout name.
            if Workout.Obstacle(intentWorkoutName: name) != nil {
                result = INSpeakableStringResolutionResult.success(with: name)
            } else {
                result = INSpeakableStringResolutionResult.needsValue()
            }
        } else if let lastWorkout = workoutHistory.last {
            // A name hasn't been supplied so suggest the last obstacle.
            result = INSpeakableStringResolutionResult.confirmationRequired(with: lastWorkout.obstacle.intentWorkoutName)
        } else {
            result = INSpeakableStringResolutionResult.needsValue()
        }

        completion(result)
    }

    func resolveWorkoutGoalUnitType(for intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutGoalUnitTypeResolutionResult) -> Void) {
        let result: INWorkoutGoalUnitTypeResolutionResult

        // Allow time based or open goals.
        switch intent.workoutGoalUnitType {
        case .hour, .minute, .second:
            result = INWorkoutGoalUnitTypeResolutionResult.success(with: intent.workoutGoalUnitType)
        case .unknown:
            // Allow open ended workout.
            isOpenEnded = true
            result = INWorkoutGoalUnitTypeResolutionResult.success(with: .minute)
        default:
            result = INWorkoutGoalUnitTypeResolutionResult.unsupported()
        }

        completion(result)
    }

    func resolveIsOpenEnded(for intent: INStartWorkoutIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
        completion(INBooleanResolutionResult.success(with: isOpenEnded))
    }

    // MARK: Intent confirmation

    func confirm(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        let response: INStartWorkoutIntentResponse

        // Validate the intent by attempting create a `Workout` with it.
        if Workout(startWorkoutIntent: intent) != nil {
            response = INStartWorkoutIntentResponse(code: .ready, userActivity: nil)
        } else {
            response = INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
        }

        completion(response)
    }

    // MARK: Intent handling

    /// - Tag: HandleIntentInExtension
    func handle(intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        // `handleInApp` will transfer handling this activity to the main app and deliver the intent to the app delegate in the background.
        let response = INStartWorkoutIntentResponse(code: .handleInApp, userActivity: nil)
        completion(response)
    }

}
