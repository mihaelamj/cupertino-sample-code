/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main structure that launches the app.
*/

import SwiftUI
import TipKit

@main
struct TipKitExamples: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        do {
            try setupTips()
        } catch {
            print("Error initializing tips: \(error)")
        }
    }

    // Various way to override tip eligibility for testing.
    // Note: These must be called before `Tips.configure()`.
    private func setupTips() throws {
        // Show all defined tips in the app.
        // Tips.showAllTipsForTesting()

        // Show some tips, but not all.
        // Tips.showTipsForTesting([tip1, tip2, tip3])

        // Hide all tips defined in the app.
        // Tips.hideAllTipsForTesting()

        // Purge all TipKit-related data.
        try Tips.resetDatastore()

        // Configure and load all tips in the app.
        try Tips.configure()
    }
}
