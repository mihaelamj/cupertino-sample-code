/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI app for watchOS.
*/

import SwiftUI

@main
struct MirroringWorkoutsSampleWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let workoutManager = WorkoutManager.shared

    @SceneBuilder var body: some Scene {
        WindowGroup {
            PagingView()
                .environmentObject(workoutManager)
        }
    }
}
