/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import AppIntents
import SwiftUI
import CoreSpotlight

@main
struct AppIntentsTravelTrackingApp: App {
    @State private var modelData = ModelData()
    @State private var navigator = Navigator.shared

    init() {
        let data = modelData
        AppDependencyManager.shared.add(dependency: data)
        let navigator = self.navigator
        AppDependencyManager.shared.add(dependency: navigator)
        AppDependencyManager.shared.add { SearchEngine() }
    }

    var body: some Scene {
        WindowGroup { /* ... */
            LandmarksSplitView()
                .environment(modelData)
                .environment(navigator)
                .frame(minWidth: 375.0, minHeight: 600.0)
                .task {
                    try? await EntityDonator.donateLandmarks(modelData: modelData)
                    TravelTrackingAppShortcuts.updateAppShortcutParameters()
                }
        }
        .windowResizability(.contentMinSize)
        .handlesExternalEvents(matching: [
            OpenLandmarkIntent.persistentIdentifier
        ])
    }
}
