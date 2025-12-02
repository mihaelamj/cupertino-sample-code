/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI

@main
struct EntryPoint: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            UIPortalView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        // Defines an immersive space as a part of the scene.
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
