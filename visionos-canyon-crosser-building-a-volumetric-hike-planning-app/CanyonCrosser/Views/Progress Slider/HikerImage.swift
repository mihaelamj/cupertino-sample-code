/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Symbol showing the hiker state.
*/

import SwiftUI
import RealityKit

struct HikerImage: View {
    @Environment(AppModel.self) var appModel

    let size: CGFloat

    var body: some View {
        Image(systemName: appModel.hikePlaybackStateComponent.isPaused ? "figure.stand" : "figure.hiking")
            .resizable()
            .scaledToFit()
            .padding(size * 0.2)
            .frame(width: size, height: size)
            .animation(.spring(response: 0.3), value: size)
            .foregroundColor(.white)
            .contentShape(Circle())
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    VStack(spacing: 40) {
        HikerImage(size: 100)
            .padding()
            .glassBackgroundEffect()

        PlayPauseButton(buttonSize: 50)
            .padding()
            .glassBackgroundEffect()
    }
}
