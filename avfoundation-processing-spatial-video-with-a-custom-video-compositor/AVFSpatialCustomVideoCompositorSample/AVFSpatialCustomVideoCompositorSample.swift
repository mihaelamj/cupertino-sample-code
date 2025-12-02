/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import os
import SwiftUI

@main
struct AVFSpatialCustomVideoCompositorSample: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
				.task {
                    UserSettings.shared.registerDefaults()
				}
        }
    }
}

// A global logger for this app.
let logger = Logger(subsystem: "AVF-SpatialCustomVideoCompositorSample", category: "app")
