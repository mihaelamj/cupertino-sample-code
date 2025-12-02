/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A landmark in the carousel.
*/

import SwiftUI
import RealityKit
import RealityKitContent

/// An item in the carousel.
struct LandmarkItemView: View {
    @Environment(AppPhaseModel.self) private var appPhaseModel
    let item: CarouselItem
    
    var body: some View {
        // Load the entity from Reality Composer Pro.
        Model3D(named: item.entityName, bundle: realityKitContentBundle) { model in
            if let model = model.model {
                model
                    .resizable()
                    .scaledToFit3D()
            }
        }
        .frame(minWidth: 200, idealWidth: 500, maxWidth: 500, minHeight: 0, idealHeight: 300, maxHeight: 300, alignment: .bottom)
        .frame(minDepth: 200, idealDepth: 500, maxDepth: 500)
        .onTapGesture {
            // Open the `GrandCanyonView` when a model is tapped.
            appPhaseModel.appPhase = .grandCanyon
        }
    }
}

#Preview(windowStyle: .volumetric) {
    @Previewable @State var item: CarouselItem = CarouselItem(name: "Mt. Fuji", country: "Japan", entityName: "CarouselFuji")
    
    LandmarkItemView(item: item)
        .environment(AppPhaseModel())
}
