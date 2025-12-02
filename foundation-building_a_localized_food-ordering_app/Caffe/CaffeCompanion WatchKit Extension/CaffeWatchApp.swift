/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The SwiftUI watch app wrapper that presents the app's content in a scene.
*/

import SwiftUI

@main
struct CaffeWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
