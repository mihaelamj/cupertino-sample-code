/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Intents for pausing and resuming a workout.
*/

import AppIntents
import Foundation

/**
 Pressing the power and Action buttons at the same time on an Apple Watch Ultra when a workout is in progress automatically triggers the pause and
 resume workout intents.
 */
struct PauseTrailActivity: PauseWorkoutIntent {
    static let openAppWhenRun: Bool = true
    static let title: LocalizedStringResource = "Pause Trail Activity"
    
    static let description = IntentDescription("Pauses tracking a trail activity.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"])
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    func perform() async throws -> some IntentResult {
        await activityTracker.pauseActivity()
        // Replace the Action button functionality with `ResumeTrailActivity`.
        return .result(actionButtonIntent: ResumeTrailActivity())
    }
}

struct ResumeTrailActivity: ResumeWorkoutIntent {
    static let openAppWhenRun: Bool = true
    static let title: LocalizedStringResource = "Resume Trail Activity"
    static let description = IntentDescription("Resumes tracking a trail activity.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"])
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    func perform() async throws -> some IntentResult {
        await activityTracker.resumeActivity()
        // Set the Action button functionality back to `NextTrailManeuver`.
        return .result(actionButtonIntent: NextTrailManeuver())
    }
}

struct EndTrailActivity: AppIntent {
    static let openAppWhenRun: Bool = true
    static let title: LocalizedStringResource = "End Trail Activity"
    static let description = IntentDescription("Ends tracking a trail activity.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"])
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    @Dependency
    private var navigationModel: NavigationModel
    
    @MainActor
    func perform() async throws -> some IntentResult {
        activityTracker.endActivity()
        navigationModel.displayInProgressActivityInfo = false
        return .result(actionButtonIntent: StartTrailActivity())
    }
}
