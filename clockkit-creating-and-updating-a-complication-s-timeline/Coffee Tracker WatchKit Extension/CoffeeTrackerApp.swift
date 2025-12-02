/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the Coffee Tracker app.
*/

import SwiftUI

@main
struct CoffeeTrackerApp: App {
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
