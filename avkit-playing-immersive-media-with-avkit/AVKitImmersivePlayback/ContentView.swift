/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main video selection interface.
*/

import SwiftUI

struct ContentView: View {

    let spacing = 20.0

    @Environment(PlayerModel.self) private var model
    @Environment(SceneProvider.self) private var sceneProvider

    var body: some View {
        ScrollView([.horizontal]) {
            HStack(spacing: spacing) {
                ForEach(Video.library) { video in
                    VideoCard(video: video)
                }
            }
        }
        .padding(spacing)
        .scrollIndicators(.hidden)
        .onChange(of: sceneProvider.scene, initial: true) { _, newScene in
            // Update the player model with the new scene.
            model.scene = newScene
        }
    }
}
