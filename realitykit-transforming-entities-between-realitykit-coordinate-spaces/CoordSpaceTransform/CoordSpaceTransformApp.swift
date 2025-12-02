/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI

/// The app's main entry point, which initializes a volumetric window and an immersive space.
@main
struct CoordSpaceTransformApp: App {
    /// The app's observable data model.
    @State private var appModel = AppModel()
    
    /// The action that dismisses an immersive space.
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    /// The action that presents an immersive space.
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some Scene {
        WindowGroup(id: "VolumetricView") {
            VolumetricView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.0, height: 1.0, depth: 1.0, in: .meters)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(appModel)
                .preferredSurroundingsEffect(.dark)
        }
    }
}
