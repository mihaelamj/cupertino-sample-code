/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarkDetailInspectorView: View {
    @Environment(ModelData.self) var modelData
    
    let landmark: Landmark
    @Binding var inspectorIsPresented: Bool

    var body: some View {
        VStack {
            Form {
                Section("Map") {
                    LandmarkDetailMapView(landmark: landmark, landmarkMapItem: modelData.mapItemsByLandmarkId[landmark.id])
                    .aspectRatio(Constants.mapAspectRatio, contentMode: .fit)
                    .cornerRadius(Constants.cornerRadius)
                }
                Section("Metadata") {
                    LabeledContent("Coordinates", value: landmark.formattedCoordinates)
                    LabeledContent("Location", value: landmark.continent)
                }
                .multilineTextAlignment(.trailing)
            }
        }
        #if os(iOS)
        .toolbarVisibility(UIDevice.current.userInterfaceIdiom == .phone ? .visible : .hidden, for: .automatic)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Button {
                    inspectorIsPresented.toggle()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        #endif
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!

    LandmarkDetailInspectorView(landmark: previewLandmark, inspectorIsPresented: .constant(true))
        .environment(modelData)
}
