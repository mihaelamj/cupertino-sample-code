/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI

@main
struct DockingApp: App {

    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()
    
    var body: some Scene {
        WindowGroup {
            if avPlayerViewModel.isPlaying {
                AVPlayerView(viewModel: avPlayerViewModel)
                    .immersiveEnvironmentPicker {
                        ImmersivePickerView(appModel: appModel)
                    }
            } else {
                ContentView {
                    avPlayerViewModel.play()
                }
            }
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
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
