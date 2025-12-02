/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the results for forward geocoding addresses into coordinates.
*/

import SwiftUI
import MapKit
import OSLog

struct GeocodeView: View {
    private let addressVisits = [
        "4643 Mill Creek Pkwy \n Kansas City, MO  64111 \n United States",
        "Jirón Madre de Dios S/N \n Lima \n Peru"
    ]
    
    @State private var addressVisitMapItems: [MKMapItem] = []

    var body: some View {
        List {
            Section() {
                ForEach(addressVisitMapItems, id: \.self) { visitMapItem in
                    VStack(alignment: .leading) {
                        Map(initialPosition: .camera(MapCamera(centerCoordinate: visitMapItem.location.coordinate, distance: 350))) {
                            Marker(item: visitMapItem)
                        }
                        .frame(height: 180)
                        .cornerRadius(20)
                        Text(visitMapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: false) ?? "address")
                            .font(.caption)
                    }
                }
            }
        }
        .listStyle(.plain)
        .onAppear {
            Task {
                var addressMapItems = [MKMapItem]()
                for address in addressVisits {
                    if let request = MKGeocodingRequest(addressString: address) {
                        do {
                            let mapitems = try await request.mapItems
                            if let mapitem = mapitems.first {
                                addressMapItems.append(mapitem)
                            }
                        } catch let error {
                            let logger = Logger()
                            logger.error("Geocoding request failed with error: \(error)")
                        }
                    }
                }
                addressVisitMapItems = addressMapItems
            }

        }
    }
}

#Preview {
    GeocodeView()
}
