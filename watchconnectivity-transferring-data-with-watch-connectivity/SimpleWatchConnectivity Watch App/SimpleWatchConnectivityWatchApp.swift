/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI app for watchOS.
*/

import SwiftUI

@main
struct SimpleWatchConnectivityWatchApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
