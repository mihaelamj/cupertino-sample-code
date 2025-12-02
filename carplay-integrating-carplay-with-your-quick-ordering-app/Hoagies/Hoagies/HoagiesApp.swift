/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point of the app.
*/

import SwiftUI

@main
struct HoagiesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView(shared: MemoryLogger.shared)
        }
    }
}
