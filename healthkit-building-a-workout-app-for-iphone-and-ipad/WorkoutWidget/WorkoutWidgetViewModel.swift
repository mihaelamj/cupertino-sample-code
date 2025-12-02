/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that you use to control the widget.
*/

import ActivityKit
import Foundation

@Observable
@MainActor final class WorkoutWidgetViewModel {
    static let shared = WorkoutWidgetViewModel()
    private init() {}
    
    // The state model for keeping track of the widget's current state.
    struct ActivityViewState: Sendable {
        var activityState: ActivityState
        var contentState: WorkoutWidgetAttributes.ContentState
        var pushToken: String? = nil
        // End the widget state controls.
        var shouldShowEndControls: Bool {
            switch activityState {
            case .active, .stale:
                return true
            case .ended, .dismissed:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        }
        var updateControlDisabled: Bool = false
        // Update the widget state controls.
        var shouldShowUpdateControls: Bool {
            switch activityState {
            case .active, .stale:
                return true
            case .ended, .dismissed:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        }
        var isStale: Bool {
            return activityState == .stale
        }
    }
    
    var activityViewState: ActivityViewState? = nil
    private var currentActivity: Activity<WorkoutWidgetAttributes>? = nil
    
    /// Starts a workout Live Activity.
    func startLiveActivity(symbol: String) {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                let workout = WorkoutWidgetAttributes(symbol: symbol)
                
                let metrics = MetricsModel(elapsedTime: 0)
                    
                let initialState = WorkoutWidgetAttributes.ContentState(
                    state: 1,
                    metrics: metrics
                )
                let activity = try Activity.request(
                    attributes: workout,
                    content: ActivityContent(state: initialState, staleDate: nil),
                    pushType: .token
                )
                self.setup(withActivity: activity)
                WorkoutManager.shared.isLiveActivityActive = true
            } catch {
                print("startLiveActivity error: \(error.localizedDescription)")
                WorkoutManager.shared.isLiveActivityActive = false
            }
        }
    }
    
    /// Updates the workout Live Activity.
    func updateLiveActivity(shouldAlert: Bool, metrics: MetricsModel) {
        Task {
            defer {
                self.activityViewState?.updateControlDisabled = false
            }
            self.activityViewState?.updateControlDisabled = true
            try await self.updateWorkoutLiveActivity(alert: shouldAlert, metrics: metrics)
        }
    }
    
    /// Ends the workout Live Activity.
    func endLiveActivity(dismissTimeInterval: Double?, metrics: MetricsModel) {
        Task {
            await self.endActivity(dismissTimeInterval: dismissTimeInterval, metrics: metrics)
        }
    }
}

private extension WorkoutWidgetViewModel {
    
    // Updates the final state of the workout activity state and sets the widget state to dismiss.
    func endActivity(dismissTimeInterval: Double?, metrics: MetricsModel) async {
        guard let activity = currentActivity else {
            return
        }
        let finalContent = WorkoutWidgetAttributes.ContentState(
            state: 1,
            metrics: metrics
        )
        let dismissalPolicy: ActivityUIDismissalPolicy
        if let dismissTimeInterval = dismissTimeInterval {
            if dismissTimeInterval <= 0 {
                dismissalPolicy = .immediate
            } else {
                dismissalPolicy = .after(.now + dismissTimeInterval)
            }
        } else {
            dismissalPolicy = .default
        }
        WorkoutManager.shared.isLiveActivityActive = false
        Task {
            await activity.end(ActivityContent(state: finalContent, staleDate: nil), dismissalPolicy: dismissalPolicy)
        }
    }
    
    // Sets up the initial workout Live Activity state and widget state.
    func setup(withActivity activity: Activity<WorkoutWidgetAttributes>) {
        self.currentActivity = activity
        self.activityViewState = .init(
            activityState: activity.activityState,
            contentState: activity.content.state,
            pushToken: activity.pushToken?.hexadecimalString
        )
        observeActivity(activity: activity)
    }
    
    // Observes for state changes in the Live Activity.
    func observeActivity(activity: Activity<WorkoutWidgetAttributes>) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor @Sendable in
                    for await activityState in activity.activityStateUpdates {
                        if activityState == .dismissed {
                            self.cleanUpDismissedActivity()
                        } else {
                            self.activityViewState?.activityState = activityState
                        }
                    }
                }
                group.addTask { @MainActor @Sendable in
                    for await contentState in activity.contentUpdates {
                        self.activityViewState?.contentState = contentState.state
                    }
                }
            }
        }
    }
    
    // Updates the state of the workout widget.
    func updateWorkoutLiveActivity(alert: Bool, metrics: MetricsModel) async throws {
        try await Task.sleep(for: .seconds(2))
        guard let activity = currentActivity else {
            return
        }
        let contentState: WorkoutWidgetAttributes.ContentState
        if alert {
            contentState = WorkoutWidgetAttributes.ContentState(
                state: -99,
                metrics: metrics
            )
        } else {
            contentState = WorkoutWidgetAttributes.ContentState(
                state: 99,
                metrics: metrics
            )
        }
        Task {
            await activity.update(
                ActivityContent<WorkoutWidgetAttributes.ContentState>(
                    state: contentState,
                    staleDate: Date.now + 15,
                    relevanceScore: alert ? 100 : 50
                ),
            )
        }
    }
    
    // Cleans up Live Activity states.
    func cleanUpDismissedActivity() {
        self.currentActivity = nil
        self.activityViewState = nil
    }
}

private extension Data {
    var hexadecimalString: String {
        self.reduce("") {
            $0 + String(format: "%02x", $1)
        }
    }
}
