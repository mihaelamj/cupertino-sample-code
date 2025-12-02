/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An ornament to go back to the carousel view.
*/

import SwiftUI

struct BackButtonView: View {
    @Environment(AppPhaseModel.self) private var appPhaseModel
    
    var body: some View {
        Button {
            appPhaseModel.appPhase = .carousel
        } label: {
            Image(systemName: "arrow.left")
        }
        .glassBackgroundEffect()
        .padding()
        .help("Back to landmark carousel")
    }
}

#Preview {
    BackButtonView()
        .environment(AppPhaseModel())
}
