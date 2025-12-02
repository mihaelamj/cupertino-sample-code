/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI

struct ContentView: View {
    private static let spacing = CGFloat(20)

    @Environment(AppModel.self) private var appModel
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ScrollView([.horizontal]) {
            HStack(spacing: Self.spacing) {
                ForEach(VideoModel.library) { video in
                    VideoCard(model: video)
                }
            }
        }
        .frame(height: 320)
        .padding(Self.spacing)
        .scrollIndicators(.hidden)
        .onChange(of: appModel.windowState) { oldState, newState in
            switch (oldState, newState) {
            case (.library, .portalDefault):
                pushWindow(id: PlayerWindow.sceneID)
            case (.portalDefault, .library):
                dismissWindow(id: PlayerWindow.sceneID)
            default:
                break
            }
        }
    }
}
