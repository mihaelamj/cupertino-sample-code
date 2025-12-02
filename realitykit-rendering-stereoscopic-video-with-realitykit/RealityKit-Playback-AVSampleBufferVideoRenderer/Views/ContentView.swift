/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import RealityKit
import SwiftUI

/// The app's top-level view.
struct ContentView: View {
    /// The factor used to scale the root entity.
    private static let scaleFactor = Float(0.5)
    
    /// An indication of the scene's operational state.
    @Environment(\.scenePhase) private var scenePhase
    
    /// A reference to the player.
    @Environment(PlayerModel.self) private var player
    
    /// The root entity of the scene.
    private let entity = Entity()

    var body: some View {
        RealityView { content in
            // Initialize the video player with the supplied renderer.
            let videoPlayerComponent = VideoPlayerComponent(videoRenderer: player.videoRenderer)
            entity.components.set(videoPlayerComponent)

            // Scale the root entity and add it to the view.
            entity.scale = SIMD3<Float>(repeating: Self.scaleFactor)
            content.add(entity)
        }
        // Set the frame to 0 so that the RealityView's origin exists on the same plane as the window.
        .frame(depth: 0)
        // Begin playback when ready.
        .onChange(of: player.isReadyToPlay) { _, ready in
            if ready {
                player.play()
            }
        }
        // Monitor the scene phase and stop playback when entering the background.
        .onChange(of: scenePhase) { _, scenePhase in
            if scenePhase == .background {
                player.stop()
            }
        }
        // Start loading the player.
        .task {
            await player.load()
        }
    }
}
