/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The root view of the app.
*/

import SwiftUI

struct ContentView: View {
    @Environment(CustomSceneDelegate.self) var sceneDelegate
    @State var multiviewStateModel = MultiviewStateModel()

    var body: some View {
        if multiviewStateModel.loadingVideos {
            ProgressView()
                .task {
                    multiviewStateModel.populate(with: defaultVideos)
                }
        } else if multiviewStateModel.videoModels.isEmpty {
            ContentUnavailableView(
                "No Videos",
                systemImage: "film.stack",
                description: Text("There are no videos to display.")
            )
        } else {
            VideoHomeView(multiviewStateModel: $multiviewStateModel)
                .onChange(of: sceneDelegate.scene, initial: true) {
                    multiviewStateModel.scene = sceneDelegate.scene
                }
        }
    }
}
