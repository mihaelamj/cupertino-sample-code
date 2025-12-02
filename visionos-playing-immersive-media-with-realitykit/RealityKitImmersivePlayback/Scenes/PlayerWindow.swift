/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The window containing a video player.
*/

import SwiftUI

struct PlayerWindow: Scene {
    static let sceneID = "PlayerWindow"

    @Environment(AppModel.self) private var appModel

    var body: some Scene {
        WindowGroup(id: PlayerWindow.sceneID) {
            if let selection = appModel.selectedVideo {
                VideoPlayerView(videoModel: selection)
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    .frame(depth: 1)
                    .ornament(attachmentAnchor: .scene(.bottom)) {
                        TransportView()
                    }
            }
        }
        .windowStyle(.plain)
    }
}
