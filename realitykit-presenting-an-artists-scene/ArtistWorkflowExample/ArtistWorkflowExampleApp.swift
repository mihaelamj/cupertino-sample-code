/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The single entry point of the app.
*/

import SwiftUI

@main
struct ArtistWorkflowExampleApp: App {
    
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 300)

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
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
