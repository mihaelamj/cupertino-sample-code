/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Switch between the carousel and the Grand Canyon depending on the state of the app.
*/

import SwiftUI

// Switch between the carousel and the Grand Canyon.
struct ContentView: View {
    @Environment(AppPhaseModel.self) private var appPhaseModel

    var body: some View {
        switch appPhaseModel.appPhase {
        case .loadingAssets:
            LoadingView()

        case .carousel:
            CarouselView()
                .frame(minWidth: 800)

        case .grandCanyon:
            GrandCanyonView()
        }
    }
}
