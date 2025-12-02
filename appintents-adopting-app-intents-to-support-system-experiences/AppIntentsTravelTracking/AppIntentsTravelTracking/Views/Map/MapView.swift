/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI
import MapKit

struct MapView: View {
    @Environment(ModelData.self) var modelData
    
    @State private var selection: MKMapItem?
    @State private var landmarkMapItems: [MKMapItem] = []
    
    var body: some View {
        Map(selection: $selection) {
            ForEach(modelData.mapItemsForLandmarks, id: \.self) { landmarkMapItem in
                Marker(item: landmarkMapItem)
            }
            .mapItemDetailSelectionAccessory()
            
            if modelData.locationFinder?.currentLocation != nil {
                UserAnnotation()
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onAppear {
            if modelData.locationFinder == nil {
                modelData.locationFinder = LocationFinder()
            }
        }
    }
}

#Preview {
    MapView()
        .environment(ModelData())
}
