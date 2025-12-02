/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom slider thumb for the timeline.
*/

import SwiftUI

/// A view that displays a slider and its button.
struct SliderThumb<Content: View>: View where Content: Sendable {
    @Environment(AppModel.self) var appModel

    /// The height of the slider and its associated views.
    let sliderHeight: CGFloat

    /// The view that determines the color of the slider button.
    @ViewBuilder
    let buttonColor: Content

    /// The width of the `SliderThumb` view.
    @State private var viewWidth: CGFloat = 0.0

    /// The padding between the button and the edges of the slider.
    var padding: CGFloat { sliderHeight / 2 }

    /// The margin between the button and the sides of the slider.
    var buttonMargin: CGFloat = 4

    /// The size of all the sides of the button.
    var size: CGFloat {
        sliderHeight - (buttonMargin * 2) - (appModel.hikerDragStateComponent.dragState == .slider ? 5 : 0)
    }

    var body: some View {
        let value = appModel.hikerProgressComponent.hikeProgress
        ZStack {
            buttonColor
                .frame(height: sliderHeight)
                .visualEffect { [padding, value] content, geometryProxy in
                    content.offset(x: -offset(for: geometryProxy.size.width, padding: padding, value: value))
                }
                .mask {
                    Circle()
                        .frame(width: size, height: size)
                        .animation(.spring(response: 0.3), value: size)
                }
                .visualEffect { [padding, value] content, geometryProxy in
                    content.offset(x: offset(for: geometryProxy.size.width, padding: padding, value: value))
                }
                .shadow(
                    color: .black.opacity(0.4),
                    radius: CGFloat(appModel.hikerDragStateComponent.dragState == .slider ? 3 : 1.5)
                )

            HStack {
                HikerImage(size: size)
                    .hoverEffect()
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("Slider"))
                            .onChanged { value in
                                appModel.sliderThumbDrag(
                                    percentage: getProgress(
                                        location: value.startLocation.x + value.translation.width
                                    )
                                )
                            }
                            .onEnded { _ in
                                appModel.sliderDragCompleted()
                            }
                    )
                    .frame(height: sliderHeight)
            }
            .frame(maxWidth: .infinity)
            .visualEffect { [padding, value] content, geometryProxy in
                content.offset(x: offset(for: geometryProxy.size.width, padding: padding, value: value))
            }
        }
        .coordinateSpace(name: "Slider")
        .onTapGesture(coordinateSpace: .local) { point in
            appModel.sliderTapped(percentage: getProgress(location: point.x))
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .local).width
        } action: { width in
            viewWidth = width
        }
    }

    nonisolated
    func offset(for width: CGFloat, padding: CGFloat, value: Float) -> CGFloat {
        let trackWidth = width - (2 * padding)
        let offset = -trackWidth / 2 + trackWidth * CGFloat(value)
        return offset
    }

    func getProgress(location: CGFloat) -> Float {
        let trackWidth = viewWidth - 2 * padding
        let positionInTrack = location - padding

        return Float(positionInTrack / trackWidth).clamped(to: 0...1)
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    SliderThumb(sliderHeight: 50) {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue,
                Color.red
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    .background(.ultraThickMaterial)
    .clipShape(.capsule)
    .padding(40)
    .glassBackgroundEffect()
}
