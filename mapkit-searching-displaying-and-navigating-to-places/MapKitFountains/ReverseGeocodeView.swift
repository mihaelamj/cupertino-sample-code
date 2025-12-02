/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the results for reverse geocoding coordinates to addresses.
*/

import SwiftUI
import MapKit

struct ReverseGeocodeView: View {
    private let fountainCoordinates = [
        // Mill Creek Park, Kansas City
        CLLocation(latitude: 39.042_617, longitude: -94.587_526),
        
        // Trevi Fountain, Rome
        CLLocation(latitude: 41.900_995, longitude: 12.483_285),
        
        // Archibald, Sydney
        CLLocation(latitude: -33.870_986, longitude: 151.211_786)
    ]
    
    @State private var fountains: [MKMapItem] = []
    
    var body: some View {
        List {
            ForEach($fountains, id: \.name) { $fountain in
                VStack(alignment: .leading) {
                    Text(fountain.name ?? "Name")
                    Text(fountain.addressRepresentations?.cityWithContext ?? "City")
                        .font(.caption)
                }
            }
        }
        .listStyle(.plain)
        .task {
            var fountainMapItems = [MKMapItem]()
            for coordinate in fountainCoordinates {
                if let request = MKReverseGeocodingRequest(location: coordinate) {
                    let mapitems = try? await request.mapItems
                    if let mapitem = mapitems?.first {
                        fountainMapItems.append(mapitem)
                    }
                }
            }
            fountains = fountainMapItems
        }
    }
}

#Preview {
    ReverseGeocodeView()
}
