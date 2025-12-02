/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/
import SwiftUI
import RealityKit
import SceneAssets

@main
struct RotationApp: App {
    init() {
        /// Register the system so RealityKit knows about it.
        RotationSystem.registerSystem()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
     }
}
