/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entire carousel view, including the label.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct CarouselView: View {
    @Environment(AppPhaseModel.self) private var appPhaseModel
    @State private var carouselModel = CarouselModel()
    @State private var dragValue: CGSize = .zero
    /// The angle that the carousel is rotated by.
    @State private var angleOffset: Angle = .zero
    /// The point in space that's furthest back in the volume.
    @State private var backOfVolume: Point3D = .zero
    
    var body: some View {
        ZStack {
            // Push the carousel to the front of the rectangular volume.
            Spacer()

            VStackLayout(spacing: 20).depthAlignment(.front) {
                // The rotational layout and bottom platter.
                CarouselBodyView(angleOffset: angleOffset, backOfVolume: backOfVolume)
                    .environment(carouselModel)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let change = value.translation.width - dragValue.width
                                let angle = Angle.degrees(-change / 5)
                                withAnimation {
                                    // Animate the change in angle for a smoother transition.
                                    self.angleOffset += angle
                                }
                                self.dragValue = value.translation
                            }
                            .onEnded { _ in
                                // Snap the carousel back to face the hiker after finishing a spin.
                                snapCarousel()
                            }
                    )

                CarouselLabelView()
                    .environment(carouselModel)
            }
            // Get the point furthest back in the carousel and save it to later set the opacity.
            .onGeometryChange3D(for: Point3D.self) { proxy in
                Point3D(x: proxy.size.width / 2, y: proxy.size.height / 2, z: proxy.size.depth)
            } action: { furthestPoint in
                backOfVolume = furthestPoint
            }
        }
    }

    /// Snaps the items in the carousel back to set points.
    func snapCarousel() {
        self.dragValue = .zero
        
        // Choose a spot to snap to based on the angle of the item.
        let index = Int(self.angleOffset.degrees) / carouselModel.degreeToSnapTo
        
        // Get the remainder of the angle left between the current angle and the index.
        let remainder = Int(self.angleOffset.degrees) % carouselModel.degreeToSnapTo
        
        // Get the angle needed.
        let angle = Angle.degrees(Double(index) * Double(carouselModel.degreeToSnapTo))
        
        // If the absolute value of the remainder is less than the cutoff, snap to the angle.
        if abs(remainder) < carouselModel.cutoffAngle {
            withAnimation {
                self.angleOffset = angle
            }
        } else {
            // Otherwise, move to the next index.
            withAnimation {
                self.angleOffset = angle + Angle.degrees(Double(
                    signOf: Double(remainder),
                    magnitudeOf: Double(carouselModel.degreeToSnapTo))
                )
            }
        }
    }
}
