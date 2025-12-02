/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import RealityKit
import PyroPanda

#if !os(visionOS)
struct ContentView: View {
    @Environment(AppModel.self) internal var appModel

    var body: some View {
        PyroPandaView()
            .overlay(alignment: .center) {
                CollectedItemsView()
                #if os(tvOS)
                    .ignoresSafeArea()
                #endif
            }.overlay {
                CongratulationsView()
            }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
#endif
