/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI app.
*/

import SwiftUI

@main
struct WorkoutsOniOSSampleApp: App {
    @UIApplicationDelegateAdaptor(WorkoutsOniOSSampleAppDelegate.self) var appDelegate
    @State private var workoutManager = WorkoutManager.shared
    @State private var navigationModel = NavigationModel()
    
    init() {
        navigationModel.observeWorkoutManager(workoutManager: workoutManager)
    }
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            switch navigationModel.viewState {
            case .startView:
                NavigationStack {
                    StartView()
                }
                .environment(workoutManager)
                .transition(.opacity)
            case .countdownView:
                CountDownView()
                    .transition(.opacity)
            case .sessionView:
                SessionView()
                    .environment(workoutManager)
                    .transition(.opacity)
            case .summaryView:
                NavigationStack {
                    SummaryView()
                }
                .environment(workoutManager)
                .transition(.opacity)
            }
        }
    }
}
