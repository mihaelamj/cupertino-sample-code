/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point and UI.
*/

import SwiftUI
import RealityKit
import ARKit

@main
struct TrackingAccessoriesApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            AccessoryTrackingView()
        }
        .windowStyle(.volumetric)
    }
}
