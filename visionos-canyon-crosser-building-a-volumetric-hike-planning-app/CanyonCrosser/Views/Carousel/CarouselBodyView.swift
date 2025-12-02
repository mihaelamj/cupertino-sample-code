/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view containing the custom layout and all entities in the carousel.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct CarouselBodyView: View {
    @Environment(CarouselModel.self) private var carouselModel
    @State private var localZPosition: Double = 0.0
    let angleOffset: Angle
    let backOfVolume: Point3D
    
    /// The white circular platter below the entities.
    struct CarouselPlatter: View {
        var body: some View {
            Model3D(named: "DonutPlatter", bundle: realityKitContentBundle) { model in
                model
                    .resizable()
                    .scaledToFit3D()
            } placeholder: {
                ProgressView()
            }
            .padding(.horizontal, 100)
        }
    }
    
    var body: some View {
        @Bindable var carouselModel = carouselModel
        
        VStackLayout(spacing: 0).depthAlignment(.center) {
            // Pushes the content to the baseplate of the volume.
            Spacer()
            // A radial custom layout.
            RadialLayout(angleOffset: angleOffset) {
                ForEach(Array(zip(0..., $carouselModel.items)), id: \.1.id) { (index, $item) in
                    // The view that contains each landmark.
                    LandmarkItemView(item: item)
                        // Set the opacity based on the z position of the item. The closer to the front of the carousel, the more opaque it is.
                        .opacity(1 - carouselModel.normalizedZPosition[index])
                    
                        // Rotate the item by -90 degrees over the x-axis to account for the rotation of the entire `RadialLayout`.
                        .rotation3DLayout(Rotation3D(angle: .degrees(-90), axis: .x))
                    
                        .onGeometryChange3D(for: Rect3D.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { newValue in
                            localZPosition = backOfVolume.z - newValue.origin.z
                            item.zPosition = localZPosition
                        }
                }
            }
            // Rotates the radial layout to be horizontal instead of vertical.
            .rotation3DLayout(Rotation3D(angle: .degrees(90), axis: .x))
            
            CarouselPlatter()
        }
    }
}
