/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A progress view that appears while the app loads assets.
*/

import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(AppPhaseModel.self) private var appPhaseModel

    var body: some View {
        ProgressView {
            Text("Loading assets…",
                 comment: "This lets people know that the app can't open yet because it's still loading assets.")
            .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassBackgroundEffect()
        .task {
            defer { appPhaseModel.appPhase = .carousel }
            // Prepare the splash screen assets before starting game.
            do {
                try await appModel.prepareAssets()
            } catch {
                assertionFailure(String(describing: error))
            }
        }
    }
}
