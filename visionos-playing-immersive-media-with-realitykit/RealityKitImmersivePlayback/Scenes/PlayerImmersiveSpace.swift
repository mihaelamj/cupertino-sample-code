/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An immersive space containing a video player.
*/

import SwiftUI

// MARK: - PlayerImmersiveSpace

private struct PlayerImmersiveSpace: Scene {
    let sceneIdentifier: String

    @Environment(AppModel.self) private var appModel

    var body: some Scene {
        ImmersiveSpace(id: sceneIdentifier) {
            if let selection = appModel.selectedVideo {
                VideoPlayerView(videoModel: selection)
            }
        }
        .immersiveContentBrightness(.automatic)
        .upperLimbVisibility(.automatic)
    }
}

// MARK: - ProgressivePlayerImmersiveSpace

struct ProgressivePlayerImmersiveSpace: Scene {
    nonisolated static let sceneID = "ProgressivePlayerImmersiveSpace"

    var body: some Scene {
        PlayerImmersiveSpace(sceneIdentifier: Self.sceneID)
            .immersionStyle(
                selection: .constant(ProgressiveImmersionStyle(immersion: 0.01...1, initialAmount: 1)),
                in: .progressive
            )
    }
}

// MARK: - SpatialPlayerImmersiveSpace

struct SpatialPlayerImmersiveSpace: Scene {
    nonisolated static let sceneID = "SpatialPlayerImmersiveSpace"

    var body: some Scene {
        PlayerImmersiveSpace(sceneIdentifier: Self.sceneID)
            .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)
            .immersiveEnvironmentBehavior(.coexist)
    }
}
