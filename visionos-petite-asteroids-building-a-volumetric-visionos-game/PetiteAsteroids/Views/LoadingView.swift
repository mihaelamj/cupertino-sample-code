/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows loading progress at the start of the game.
*/

import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel
    var body: some View {
        VStack {
            ProgressView(value: appModel.loadingPercentDone, label: { Text("Loading...").font(.system(.title, design: .rounded)) })
                .tint(.gray)
                .padding()
        }
        .attachment()
        .glassBackgroundEffect()
    }
}

#Preview {
    LoadingView()
}
