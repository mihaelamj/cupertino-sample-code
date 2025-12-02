/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file that runs the app and contains a window and an immersive space.
*/

import SwiftUI

@main
struct HeadTrackingApp: App {
    @State private var appModel: AppModel = AppModel()
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    // Register the system and the component.
    init() {
        FollowSystem.registerSystem()
        FollowComponent.registerComponent()
    }
    var body: some Scene {
        WindowGroup {
            TogglePanel()
                .environment(appModel)
        }
        .defaultSize(CGSize(width: 400, height: 200))
        
        ImmersiveSpace(id: "immersiveSpace") {
            ImmersiveView()
                .environment(appModel)
        }
    }
}
