/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app structure.
*/

import SwiftUI

/// The main app structure.
@main
struct RealityKitPlaybackApp: App {
    /// An object that controls the video playback behavior.
    @State private var player = PlayerModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .frame(width: 1600, height: 900)
        }
        // Expressly constrain window size to that of its content.
        .windowResizability(.contentSize)
        // Disable background glass.
        .windowStyle(.plain)
    }
}
