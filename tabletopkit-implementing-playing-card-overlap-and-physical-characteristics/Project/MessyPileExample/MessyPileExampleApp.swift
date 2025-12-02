/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point to the messy pile sample app.
*/

import SwiftUI
import Spatial
import RealityKit

@main
struct MessyPileExampleApp: App {
    @State var playground = Playground()
    var body: some SwiftUI.Scene {
        WindowGroup {
            PlaygroundView()
                .environment(playground)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1, depth: 1, in: .meters)
    }
}
