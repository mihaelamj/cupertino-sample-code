/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The controls in the timeline view.
*/

import SwiftUI

struct HikeControls: View {
    @Environment(AppModel.self) var appModel
    let volumeSize: Size3D
    let hike: Hike

    @State private var timelineLabels: [TimelineLabel] = []

    @ScaledMetric var additionalScaledWidth = 300.0

    var body: some View {
        if volumeSize.width < 1000 {
            CompactControlsView()
        } else {
            TimelineView(
                hike: hike,
                timelineLabels: appModel.timelineLabels
            )
            .frame(width: 700.0 + additionalScaledWidth)
        }
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    @Previewable @State var volumeSize = Size3D(width: 1400, height: 500, depth: 500)

    VStack(spacing: 20) {
        HikeControls(
            volumeSize: volumeSize,
            hike: MockData.brightAngel
        )

        Button {
            volumeSize.width = volumeSize.width == 1400 ? 800 : 1400
        } label: {
            Text("Toggle between full and minimal view")
        }
        .padding()
        .glassBackgroundEffect()
    }
}
