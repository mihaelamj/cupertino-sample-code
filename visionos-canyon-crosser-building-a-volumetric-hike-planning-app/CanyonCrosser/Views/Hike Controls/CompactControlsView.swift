/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A compact version of the timeline view.
*/

import SwiftUI

struct CompactControlsView: View {
    @ScaledMetric var buttonSize: CGFloat = 44.0

    var body: some View {
        HStack(spacing: 20) {
            PlayPauseButton(buttonSize: buttonSize)
            ResetButton(buttonSize: buttonSize)
        }
        .padding()
        .glassBackgroundEffect(in: .capsule)
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    CompactControlsView()
}
