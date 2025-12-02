/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent for people to gather statistics about the activities they track, and use that information with
 other apps in a shortcut.
*/

import AppIntents
import Foundation

struct SummarizeActivities: AppIntent {
    static let title: LocalizedStringResource = "Summarize Activities"
    static let description = IntentDescription("Summarizes activities that the app tracks to monitor progress toward a goal.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"],
                                               resultValueName: "Activity Statistics")
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    @Dependency
    private var trailManager: TrailDataManager
    
    /**
     An intent that completes an action or provides a summary to people can return an app entity with additional details.
     By returning the app entity, people can take the data from the properties of this intent and
     use it with other apps, enabling them to build their own powerful features that meet their specific needs.
     */
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<ActivityStatisticsSummary> {
        /**
         Summarize all activities, such as for a Year to Date summary. The app doesn't store the data in the`ActivityStatisticsSummary`
         structure that returns from `activityTracker`, because the data continually changes based on how people use the app. Because this
         data is continually changing, the app  conforms `ActivityStatisticsSummary` to `TransientAppEntity` instead of `AppEntity`.
         */
        let stats = await activityTracker.activityStatistics
        if await activityTracker.activityHistory.isEmpty {
            return .result(value: stats, dialog: IntentDialog("You haven't logged a workout yet. Let's get started!"))
        } else {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.allowedUnits = [.month, .year]
            let summaryString = formatter.string(from: stats.summaryStartDate, to: Date())!
            
            let dialog = IntentDialog("You completed \(stats.workoutsCompleted) workouts in \(summaryString). Incredible!")
            return .result(value: stats, dialog: dialog)
        }
    }
}
