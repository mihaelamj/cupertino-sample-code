/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view containing content to be shown in the app.
*/

import RealityKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ImagePresentationView()
            .environment(appModel)
            .ornament(
                visibility: appModel.spatial3DImageState == .generating
                    ? .hidden : .visible,
                attachmentAnchor: .scene(.bottomFront),
                ornament: {
                    OrnamentsView(imageCount: appModel.imageURLs.count)
                }
            )
    }
}
