/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point into the app.
*/

import SwiftUI

@main
struct SwiftChartsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        #endif
    }
}
