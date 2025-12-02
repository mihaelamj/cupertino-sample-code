/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

@main
struct RealityKitImmersivePlaybackApp: App {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var appModel = AppModel()
    private var playerModel: PlayerModel {
        appModel.playerModel
    }

    var body: some Scene {
        makeDefaultScenes()
            .environment(appModel)
            .environment(playerModel)
            .onChange(of: appModel.pendingStage) { _, stage in
                let currentStage = appModel.stage
                guard let pendingStage = stage else {
                    return
                }

                Task { @MainActor in
                    await transitionStage(from: currentStage, to: pendingStage)
                }
            }
            .onChange(of: appModel.windowState) { oldState, newState in
                switch (oldState, newState) {
                case (.library, nil):
                    dismissWindow(id: LibraryWindow.sceneID)
                case (.portalDefault, nil):
                    dismissWindow(id: PlayerWindow.sceneID)
                    dismissWindow(id: LibraryWindow.sceneID)
                case (.portalToggled, .library):
                    openWindow(id: LibraryWindow.sceneID)
                    dismissWindow(id: PlayerWindow.sceneID)
                case (.portalToggled, nil):
                    dismissWindow(id: PlayerWindow.sceneID)
                case (nil, .library):
                    openWindow(id: LibraryWindow.sceneID)
                case (nil, .portalToggled):
                    openWindow(id: PlayerWindow.sceneID)
                default:
                    break
                }
            }
            .onChange(of: playerModel.didPlayToEndTime) { _, didPlayToEnd in
                guard didPlayToEnd else { return }
                appModel.requestStage(.browsing)
                appModel.reset()
            }
    }

    // MARK: Private behavior

    private func closeImmersivePlayer() async {
        guard appModel.immersiveSpaceState != .closed else {
            debugPrint("Immersive space is already closed...")
            return
        }

        appModel.immersiveSpaceState = .inTransition
        await dismissImmersiveSpace()
        appModel.immersiveSpaceState = .closed
    }

    @SceneBuilder
    private func makeDefaultScenes() -> some Scene {
        LibraryWindow()
        PlayerWindow()
        ProgressivePlayerImmersiveSpace()
        SpatialPlayerImmersiveSpace()
    }

    private func openImmersivePlayer(identifier: String) async {
        guard appModel.immersiveSpaceState != .open else {
            debugPrint("Immersive space is already open.")
            return
        }

        appModel.immersiveSpaceState = .inTransition
        let result = await openImmersiveSpace(id: identifier)

        switch result {
        case .opened:
            appModel.immersiveSpaceState = .open
        case .error, .userCancelled:
            appModel.immersiveSpaceState = .closed
            debugPrint("Failed to open immersive space: \(result)")
        @unknown default:
            debugPrint("Unrecognized case: \(result) — please update the switch to handle it.")
        }
    }

    private func transitionStageFromBrowsingToPlayback(scene: AppModel.PlaybackScene) async {
        switch scene {
        case .immersive(let sceneID):
            await openImmersivePlayer(identifier: sceneID)
            appModel.windowState = nil
        case .window:
            appModel.windowState = .portalDefault
        }
    }

    private func transitionStageFromPlaybackToBrowsing(scene: AppModel.PlaybackScene) async {
        appModel.windowState = .library
        switch scene {
        case .immersive:
            await closeImmersivePlayer()
        case .window:
            break
        }
    }

    private func transitionPlaybackStages(
        from origin: AppModel.PlaybackScene,
        to destination: AppModel.PlaybackScene
    ) async {
        switch destination {
        case .immersive(let sceneID):
            await openImmersivePlayer(identifier: sceneID)
            appModel.windowState = nil
        case .window:
            appModel.windowState = .portalToggled
            await closeImmersivePlayer()
        }
    }

    private func transitionStage(from origin: AppModel.Stage, to destination: AppModel.Stage) async {
        guard origin != destination else {
            return
        }
        debugPrint("Attempting stage transition: \(origin) -> \(destination)")
        
        defer {
            appModel.commitStage(destination)
        }

        switch (origin, destination) {
        case (.browsing, .playing(let destinationScene)):
            await transitionStageFromBrowsingToPlayback(scene: destinationScene)
        case (.playing(let originScene), .browsing):
            await transitionStageFromPlaybackToBrowsing(scene: originScene)
        case (.playing(let originScene), .playing(let destinationScene)):
            await transitionPlaybackStages(from: originScene, to: destinationScene)
        default:
            debugPrint("Unsupported stage transition: \(origin) -> \(destination)")
        }
    }
}
