/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The popover view for trailheads and rest stops.
*/

import SwiftUI

struct PopoverView<Content: View>: View {
    @Environment(AppModel.self) var appModel

    let title: String
    let imageName: String
    let description: String

    @ViewBuilder
    let footer: Content

    let tightPadding = 16.0
    let padding = 20.0

    @ScaledMetric var extraWidth = 50.0
    @ScaledMetric var extraHeight = 100.0

    private var stops: [Gradient.Stop] {
        // Ease out curve.
        func easeOutQuad(xPosition: CGFloat) -> CGFloat {
            1 - (1 - xPosition) * (1 - xPosition)
        }

        var stops: [Gradient.Stop] = []
        for stride in stride(from: CGFloat(0.0), to: 1.0, by: 0.05) {
            let value = easeOutQuad(xPosition: stride)

            stops.append(Gradient.Stop(
                color: Color.white.opacity(1 - value),
                location: stride
            ))
        }

        return stops
    }

    let scrollViewBottomMargin: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: padding) {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, tightPadding)

                    Text(description)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .padding(.horizontal, padding)
                        .padding(.bottom)
                }
                .padding(.bottom, scrollViewBottomMargin)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                PopoverTitleView(title: title)
                    .hidden()
            }
            .overlay(alignment: .top) {
                PopoverTitleView(title: title)
                    .background {
                        Color.clear
                        .background(Material.regular)
                        .mask(LinearGradient(
                            colors: [.red, .red.opacity(0)],
                            startPoint: .center,
                            endPoint: .bottom
                        ))
                    }

            }
            .scrollIndicators(.hidden)
            .padding(.bottom, 6)
            .mask(
                VStack(spacing: 0) {
                    Rectangle()

                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: stops),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: scrollViewBottomMargin)
                }
                    .clipShape(.rect(
                        bottomLeadingRadius: 8,
                        bottomTrailingRadius: 8
                    ))
                    .allowsHitTesting(false)
            )

            footer
                .padding(.horizontal, padding)
        }
        .padding(.bottom, tightPadding)
        .frame(width: 316.0 + extraWidth, height: 450.0 + extraHeight)
        .glassBackgroundEffect()
        .presentationBreakthroughEffect(appModel.debugSettings.popoverBreakthroughEffectOption.breakthroughEffect)
        .onAppear {
            appModel.popoverIsPresented = true
        }
        .onDisappear {
            appModel.popoverIsPresented = false
        }
    }
}
