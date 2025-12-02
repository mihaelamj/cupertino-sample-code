/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Initializes the app, manages the main content and immersive AR spaces, and maintains the app state using an app model.
*/
import SwiftUI

@main
struct ObjectTrackingExperiencesSampleApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
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
