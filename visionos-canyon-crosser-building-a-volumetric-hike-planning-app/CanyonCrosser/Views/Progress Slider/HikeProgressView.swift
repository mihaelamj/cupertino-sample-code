/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to visualize the hike progress.
*/

import SwiftUI

struct HikeProgressView: View {
    @Environment(AppModel.self) var appModel
    
    let sliderHeight: CGFloat
    let timelineLabels: [TimelineLabel]

    @State var lastManualOffset: CGFloat = 0.0

    @ScaledMetric var spacing = 10

    var weather: [Weather] { timelineLabels.map { $0.weather } }
    var times: [Date] { timelineLabels.map { $0.time } }

    var colorGradient: LinearGradient {
        // Create an array of colors from the weather temperatures.
        LinearGradient(gradient: Gradient(colors: weather.map(\.color)), startPoint: .leading, endPoint: .trailing)
    }

    struct ProgressBackground<GradientView: View>: View {
        @ScaledMetric var bottomGradientHeight = 2

        let weather: [Weather]
        let times: [Date]
        let height: CGFloat

        @ViewBuilder
        let colorGradient: GradientView

        var maskedContent: some View {
            colorGradient
                .mask {
                    VStack {
                        Spacer()

                        WeatherOrTimeView(
                            display: .weather,
                            weather: weather,
                            times: times
                        )

                        Spacer()

                        Rectangle()
                            .frame(height: bottomGradientHeight)
                    }
                }
                .frame(height: height)
        }

        var body: some View {
            maskedContent
                .background(.ultraThickMaterial)
                .background {
                    colorGradient
                        .mask {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.0),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
                .clipShape(.capsule)
        }
    }

    var body: some View {
        VStack(spacing: spacing) {
            WeatherOrTimeView(
                display: .time,
                weather: weather,
                times: times
            )

            ZStack {
                ProgressBackground(
                    weather: weather,
                    times: times,
                    height: sliderHeight
                ) {
                    colorGradient
                }

                SliderThumb(sliderHeight: sliderHeight) {
                    colorGradient
                }
            }
            .frame(height: sliderHeight)
            .font(.caption)
        }
        .fontWeight(.medium)
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    ScrollView {
        VStack(spacing: 15) {
            ForEach(0..<((MockData.timelineLabels.count - 1) / 3), id: \.self) { index in
                HikeProgressView(
                    sliderHeight: 50,
                    timelineLabels: Array(MockData.timelineLabels[(index * 3)..<MockData.timelineLabels.count])
                )
            }
        }
        .padding(30)
    }
    .glassBackgroundEffect()
}

