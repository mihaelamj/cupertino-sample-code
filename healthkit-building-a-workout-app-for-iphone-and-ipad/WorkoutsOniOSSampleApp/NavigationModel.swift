/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The navigation model for a SwiftUI app.
*/

import Foundation
import SwiftUI

@Observable
@MainActor
class NavigationModel {
    enum NavigationState {
        case startView
        case countdownView
        case sessionView
        case summaryView
    }
    
    var viewState: NavigationState = .startView
    
    /// Observe the workout manager state and update the navigation model state accordingly.
    func observeWorkoutManager(workoutManager: WorkoutManager) {
        withObservationTracking {
            switch workoutManager.state {
            case .notStarted:
                self.viewState = .startView
            case .prepared:
                self.viewState = .countdownView
            case .running, .paused:
                self.viewState = .sessionView
            case .stopped, .ended:
                self.viewState = .summaryView
            @unknown default:
                fatalError("Unknown HKWorkoutSessionState in \(#function)")
            }
        } onChange: {
            Task { @MainActor [weak workoutManager, weak self] in
                guard let workoutManager, let self else {
                    return
                }
                // Reobserve after each state change.
                self.observeWorkoutManager(workoutManager: workoutManager)
            }
        }
    }
}
