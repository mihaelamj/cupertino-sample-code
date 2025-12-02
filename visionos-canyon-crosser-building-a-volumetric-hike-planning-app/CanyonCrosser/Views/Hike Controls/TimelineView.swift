/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entire timeline, including date pickers and controls.
*/

import SwiftUI

struct TimelineView: View {
    @Environment(AppModel.self) private var appModel
    @ScaledMetric var buttonSize: CGFloat = 44.0

    let hike: Hike
    let timelineLabels: [TimelineLabel]

    var dimToolbar: Bool {
        appModel.popoverIsPresented && appModel.debugSettings.popoverBreakthroughEffectOption == .subtlePlusOpacity
    }

    var body: some View {
        VStack(spacing: 22) {
            @Bindable var appModel = appModel
            HStack(alignment: .center, spacing: 25) {
                DateButton(
                    title: "Depart",
                    date: $appModel.hikeTimingComponent.departureDate
                )

                Spacer()

                TimelineTitleView(
                    title: hike.name,
                    sunriseTime: MockData.sunriseTime,
                    sunsetTime: MockData.sunsetTime
                )

                Spacer()

                DateButton(
                    title: "Arrive",
                    date: $appModel.hikeTimingComponent.arrivalDate
                )
            }

            HStack(alignment: .bottom, spacing: 16) {
                PlayPauseButton(buttonSize: buttonSize)
                HikeProgressView(sliderHeight: buttonSize, timelineLabels: timelineLabels)
                ResetButton(buttonSize: buttonSize)
            }
            .buttonBorderShape(.circle)

        }
        .padding(16)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32))
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 15
        }
        .breakthroughEffect(appModel.popoverIsPresented ? .none : appModel.debugSettings.toolbarBreakthroughEffectOption.breakthroughEffect)
        .animation(.default) { content in
            content.opacity(dimToolbar ? 0.2 : 1.0)
        }
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    TimelineView(hike: MockData.brightAngel, timelineLabels: MockData.timelineLabels)
}
