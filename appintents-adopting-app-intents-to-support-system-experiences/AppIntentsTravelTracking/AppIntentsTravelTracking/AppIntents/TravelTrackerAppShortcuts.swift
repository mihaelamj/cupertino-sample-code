/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
All app shortcuts for TravelTracking.
*/

import AppIntents

struct TravelTrackingAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NavigateIntent(),
            phrases: [
                "Navigate in \(.applicationName)",
                "Navigate to \(\.$navigationOption) in \(.applicationName)"
            ],
            shortTitle: "Navigate",
            systemImageName: "arrowshape.forward"
        )
        AppShortcut(
            intent: ClosestLandmarkIntent(),
            phrases: [
                "Find closest landmark in \(.applicationName)"
            ],
            shortTitle: "Find Closest",
            systemImageName: "location"
        )
        AppShortcut(
            intent: OpenLandmarkIntent(),
            phrases: [
                "Open in \(.applicationName)",
                "Open \(\.$target) in \(.applicationName)"
            ],
            shortTitle: "Open",
            systemImageName: "building.columns"
        )
    }
}
