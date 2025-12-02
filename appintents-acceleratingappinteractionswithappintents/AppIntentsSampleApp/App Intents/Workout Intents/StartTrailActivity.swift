/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to start tracking trail activity.
*/

import AppIntents
import Foundation
import OSLog

/**
 On Apple Watch Ultra, the system automatically identifies intents conforming to `StartWorkoutIntent`. People can associate
 these intents with the Action button in the Settings app, so that pressing the Action button calls this intent.
 */
struct StartTrailActivity: StartWorkoutIntent {
    
    /// The intent's title, which the app displays throughout the system.
    static let title: LocalizedStringResource = "Start Trail Activity"
    
    /**
     The Shortcuts app displays the description to the user. The optional `categoryName` parameter allows you to group your app's related
     intents. The optional `searchKeywords` parameter helps people find your intent when searching for it in the Shortcuts app.
     */
    static let description = IntentDescription("Starts tracking a trail activity.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"])
    
    /// A sentence describing the intent's configuration, visible in the Shortcuts app.
    static var parameterSummary: some ParameterSummary {
        Summary("Start tracking my \(\.$workoutStyle) activity")
    }
    
    /**
     Set to `true` so that when people press the Action button on Apple Watch Ultra, the app comes to the foreground to start the workout
     or to prompt people for HealthKit authorization.
     */
    static let openAppWhenRun: Bool = true

    /**
     These suggestions appear as options in the Settings app when people configure which workout to start by pressing the Action button,
     and in the Shortcuts app.
     */
    static let suggestedWorkouts: [StartTrailActivity] = [
        StartTrailActivity(style: .hiking),
        StartTrailActivity(style: .biking)
    ]

    /// A description of the activity that the system shows people, such as when they configure the Action button.
    var displayRepresentation: DisplayRepresentation {
        ActivityStyle.caseDisplayRepresentations[workoutStyle] ?? "Unknown Activity Style"
    }

    /// The type of activity, such as skiing or jogging.
    @Parameter(title: "Activity", description: "The activity to track, such as skiing.")
    var workoutStyle: ActivityStyle
    
    @Dependency
    private var navigationModel: NavigationModel
    
    @Dependency
    private var trailManager: TrailDataManager
    
    @Dependency
    private var activityTracker: ActivityTracker

    func perform() async throws -> some IntentResult {
        Logger.activityTracking.debug("StartTrailActivity perform called")
        
        if await activityTracker.isActivityTrackingAuthorized {
            try await startActivityTracking()
        } else {
            /**
             When a person presses the Action button on Apple Watch Ultra, the watch displays an orange overlay until the intent returns a
             result. If the person hasn't already granted HealthKit authorization for the app, this overlay covers the HealthKit
             authorization screen. Instead, request HealthKit authorization using a `Task`, allowing the intent to return quickly.
             */
            Logger.activityTracking.debug("Activity tracking not yet authorized, requesting permission")
            Task {
                let authorized = try await activityTracker.requestActivityTrackingAuthorization()
                if !authorized {
                    Logger.activityTracking.error("Activity tracking authorization denied")
                } else {
                    do {
                        try await startActivityTracking()
                    } catch {
                        Logger.activityTracking.error("Activity tracking failed to start from within a StartTrailActivity Task")
                    }
                }
            }
        }
        
        /**
         To configure an intent for the Action button, you can either return from the intent with a result containing the
         `actionButtonIntent` parameter, or you can donate the intent for the Action button, which occurs in
         `startNewActivity(_:,on:)`.
         */
        return .result()
    }
    
    @MainActor
    private func startActivityTracking() async throws {
        /**
         Record the activity on a random trail that allows the activity type. The activity type can be any value from `ActivityStyle`, not just
         those in `suggestedWorkouts`, such as if people run the intent without specifying the `workoutStyle` parameter.
         */
        let collection = trailManager.completeTrailCollection
        var randomTrail: Trail!
        while randomTrail == nil {
            let randomTrailID = collection.members.randomElement()!
            let trail = trailManager.trail(with: randomTrailID)
            if let trail, trail.activities.contains(workoutStyle) {
                randomTrail = trail
            }
        }
        Logger.activityTracking.debug("Picked random trail that allows activity \(workoutStyle.rawValue): \(randomTrail.name)")
        
        do {
            try await activityTracker.startNewActivity(workoutStyle, on: randomTrail)
            Logger.activityTracking.debug("Activity tracking started from StartTrailActivity")
        } catch {
            Logger.activityTracking.error("Activity tracking failed to start from StartTrailActivity")
            throw TrailIntentError.workoutDidNotStart
        }
        
        // When the activity tracking starts, display the trail in the UI so that people can see the tracking in the Activity History.
        navigationModel.displayInProgressActivityInfo = true
    }
}
