/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/

import SwiftUI
import PyroPanda
import RealityKit

@main
struct PyroPandaRealityKitApp: App {

    @State private var appModel = AppModel()

#if os(visionOS)
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    var immersionStyle: ProgressiveImmersionStyle {
        .progressive(
            0.1...0.5,
            initialAmount: 0.15,
            aspectRatio: .portrait
        )
    }
#endif // os(visionOS)
    var body: some SwiftUI.Scene {
        WindowGroup(id: "mainWindow") {
            #if os(visionOS)
            LaunchScreen().environment(appModel)
            #else
            ContentView().environment(appModel)
            #endif
        }
        #if os(visionOS)
        .windowResizability(.contentMinSize)
        #endif

#if os(visionOS)
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
        .immersionStyle(
            selection: .constant(self.immersionStyle),
            in: self.immersionStyle
        )

        WindowGroup(id: "gameStatus") {
            VStack(alignment: .center) {
                if appModel.levelFinished {
                    CongratulationsView()
                } else {
                    CollectedItemsView()
                }
                ToggleImmersiveSpaceButton { newState in
                    if newState == .open {
                        openWindow(id: "gameStatus")
                        // Give it some time to open the game status window.
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.2))
                            dismissWindow(id: "mainWindow")
                        }
                    } else {
                        openWindow(id: "mainWindow")
                        if appModel.levelFinished { appModel.reset() }
                        // Give it some time to open the main window.
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(0.2))
                            dismissWindow(id: "gameStatus")
                        }
                    }
                }
            }
            .environment(appModel)
            .frame(width: 400, height: appModel.levelFinished ? 200 : 100, alignment: .center)
            .padding()
            .onAppear {
                appModel.displayOverlaysVisible = true
            }
        }
        .windowResizability(.contentSize)
        .defaultWindowPlacement { _, _ in
            WindowPlacement(.utilityPanel)
        }
#endif // os(visionOS)
    }

    init() {
        PyroPanda.components.forEach { componentType in
            componentType.registerComponent()
        }
    }
}
