/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays a button to toggle the immersive space.
*/
import SwiftUI

struct ContentView: View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack {
            Spacer()
#if targetEnvironment(simulator)
            Text("This app isn't supported on the simulator. Please run it on Apple Vision Pro.")
#endif
            ToggleImmersiveSpaceButton()
                .padding()
#if targetEnvironment(simulator)
            .disabled(true)
#endif
        }
        .padding()
        .onChange(of: scenePhase, { _, newValue in
            if (newValue == .background || newValue == .inactive) &&
                appModel.immersiveSpaceState != .inTransition {
                Task {
                    await dismissImmersiveSpace()
                }
            }
        })
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
