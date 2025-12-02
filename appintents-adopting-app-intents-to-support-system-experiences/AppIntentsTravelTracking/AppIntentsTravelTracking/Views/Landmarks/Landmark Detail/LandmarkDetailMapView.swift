/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI
import MapKit

struct LandmarkDetailMapView: View {
    let landmark: Landmark
    var landmarkMapItem: MKMapItem?

    var body: some View {
        Map(initialPosition: .region(landmark.coordinateRegion), interactionModes: []) {
            if let landmarkMapItem = landmarkMapItem {
                Marker(item: landmarkMapItem)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!
    let previewMapItem = modelData.mapItemsByLandmarkId[1012]

    LandmarkDetailMapView(landmark: previewLandmark, landmarkMapItem: previewMapItem)
}
