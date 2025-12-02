/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app structure.
*/

import OSLog
import SwiftUI

/// The entry point for the app.
@main
struct SceneReconstructionExampleApp: App {
    @State private var model = EntityModel()

    var body: some Scene {
        ImmersiveSpace(id: cubeMeshInteractionID) {
            CubeMeshInteraction()
                .environment(model)
        }
    }
}

let logger = Logger(subsystem: "com.apple-samplecode.SceneReconstructionExample", category: "general")
