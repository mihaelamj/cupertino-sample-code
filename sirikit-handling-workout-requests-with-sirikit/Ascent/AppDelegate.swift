/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import Intents
import AscentFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Pass the activity to the `WorkoutsController` to handle.
        if let navigationController = window?.rootViewController as? UINavigationController {
            restorationHandler(navigationController.viewControllers)
        }

        return true
    }

    /// - Tag: HandleIntentInApp
    func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
        if let intent = intent as? INStartWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INCancelWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INPauseWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INEndWorkoutIntent {
            completionHandler(handle(intent))
        } else if let intent = intent as? INResumeWorkoutIntent {
            completionHandler(handle(intent))
        } else {
            preconditionFailure("Trying to handle unknown intent type")
        }
    }

    private func handle(_ startWorkoutIntent: INStartWorkoutIntent) -> INStartWorkoutIntentResponse {
        var workoutHistory = WorkoutHistory.load()
        let response: INStartWorkoutIntentResponse

        if let workout = Workout(startWorkoutIntent: startWorkoutIntent) {
            workoutHistory.start(newWorkout: workout)
            response = INStartWorkoutIntentResponse(code: .success, userActivity: nil)
        } else {
            response = INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
        }

        return response
    }

    private func handle(_ pauseWorkoutIntent: INPauseWorkoutIntent) -> INPauseWorkoutIntentResponse {
        var workoutHistory = WorkoutHistory.load()
        let response: INPauseWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state == .active {
            workoutHistory.pauseActiveWorkout()
            response = INPauseWorkoutIntentResponse(code: .success, userActivity: nil)
        } else {
            response = INPauseWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        return response
    }

    private func handle(_ resumeWorkoutIntent: INResumeWorkoutIntent) -> INResumeWorkoutIntentResponse {
        var workoutHistory = WorkoutHistory.load()
        let response: INResumeWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state == .paused {
            workoutHistory.resumeActiveWorkout()
            response = INResumeWorkoutIntentResponse(code: .success, userActivity: nil)
        } else {
            response = INResumeWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        return response
    }

    private func handle(_ endWorkoutIntent: INEndWorkoutIntent) -> INEndWorkoutIntentResponse {
        var workoutHistory = WorkoutHistory.load()
        let response: INEndWorkoutIntentResponse

        if workoutHistory.activeWorkout != nil {
            workoutHistory.endActiveWorkout()
            response = INEndWorkoutIntentResponse(code: .success, userActivity: nil)
        } else {
            response = INEndWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        return response
    }

    private func handle(_ cancelWorkoutIntent: INCancelWorkoutIntent) -> INCancelWorkoutIntentResponse {
        var workoutHistory = WorkoutHistory.load()
        let response: INCancelWorkoutIntentResponse

        if let workout = workoutHistory.activeWorkout, workout.state != .ended {
            workoutHistory.endActiveWorkout()
            response = INCancelWorkoutIntentResponse(code: .success, userActivity: nil)
        } else {
            response = INCancelWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }

        return response
    }

}
