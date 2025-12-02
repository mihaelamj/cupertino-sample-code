/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point.
*/

import SwiftUI

@main
struct SpatialSculptingApp: App {

    init() {
        ComputeDispatchSystem.registerSystem()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().frame(width: 1500, height: 1500).frame(depth: 1500)
        }
        .windowStyle(.volumetric)
    }
}
