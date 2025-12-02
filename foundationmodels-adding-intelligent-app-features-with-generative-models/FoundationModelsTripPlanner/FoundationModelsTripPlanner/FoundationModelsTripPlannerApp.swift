/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main function for the FoundationModelsTripPlanner app.
*/

import SwiftUI

@main
struct FoundationModelsTripPlannerApp: App {
    private var modelData = ModelData.shared

    var body: some Scene {
        WindowGroup {
            LandmarksView()
                .environment(modelData)
        }
    }
}
