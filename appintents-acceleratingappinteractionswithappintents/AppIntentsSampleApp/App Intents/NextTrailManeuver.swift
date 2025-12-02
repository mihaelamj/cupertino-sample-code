/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom intent people run by pressing the Action button on Apple Watch Ultra.
*/

import AppIntents
import Foundation
import OSLog

struct NextTrailManeuver: AppIntent {
    
    static let title: LocalizedStringResource = "Get Next Navigation Step"
    static let description = IntentDescription("Provides the next step during navigation, such as when to take an upcoming turn.")
    
    /// Hide this intent from the Shortcuts app because its use targets the Action button.
    static let isDiscoverable = false
    
    @Dependency
    private var navigationModel: NavigationModel
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        Logger.activityTracking.debug("NextTrailManeuver perform called")
        
        if activityTracker.activityInProgress == nil {
            /// This intent isn't useful if there is no active activity.
            throw TrailIntentError.activeActivityNotFound
        }
        
        let distanceFormatter = MeasurementFormatter()
        distanceFormatter.numberFormatter.maximumFractionDigits = 2
        let nextTurnDistance = distanceFormatter.string(from: Measurement<UnitLength>(value: 300, unit: .meters))
        activityTracker.nextManeuver = "Turn right in \(nextTurnDistance) to return to the parking lot and complete your activity."
        
        /// Navigate to a view in the app that shows the active activity, including the instructions for the next maneuver.
        navigationModel.displayInProgressActivityInfo = true
        
        /**
         If you return `.result()`, the Action button continues to call this intent on each button press until the app returns or donates a
         different intent.
         */
        return .result(actionButtonIntent: EndTrailActivity(), dialog: "\(activityTracker.nextManeuver ?? "")")
    }
}
