/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The single entry point of the app.
*/

import SwiftUI

@main
struct RealityKitAnimationApp: App {
    
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .volumeBaseplateVisibility(.visible)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
    }
}
