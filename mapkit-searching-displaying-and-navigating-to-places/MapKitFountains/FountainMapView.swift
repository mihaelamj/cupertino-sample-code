/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view with a map that searches for fountains and displays them on a map.
*/

import CoreLocation
import SwiftUI
import MapKit
import GeoToolbox
import OSLog

struct DublinFountains {
    static private let descriptors = [
        PlaceDescriptor(
            representations: [.coordinate(CLLocationCoordinate2D(latitude: 53.339_444, longitude: -6.258_739))],
            commonName: "Lady Grattan Drinking Fountain"
        ),
        PlaceDescriptor(
            representations: [.address("121-122 James's St \n Dublin 8 \n D08 ET27 \n Ireland")],
            commonName: "Obelisk Fountain"
        ),
        PlaceDescriptor(
            representations: [.coordinate(CLLocationCoordinate2D(latitude: 53.334_948, longitude: -6.260_813))],
            commonName: "Fountain at Iveagh Gardens"
        ),
        PlaceDescriptor(
            representations: [.coordinate(CLLocationCoordinate2D(latitude: 53.347_673, longitude: -6.290_198))],
            commonName: "Anna Livia"
        )
    ]
    
    static func fountainMapItems() async -> [MKMapItem] {
        var fountains: [MKMapItem] = []
                
        for descriptor in descriptors {
            let request = MKMapItemRequest(placeDescriptor: descriptor)
            if let fountain = try? await request.mapItem {
                fountains.append(fountain)
            }
        }
                
        return fountains
    }
}

struct FountainMapView: View {
    @State private var fountains: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapRoute: MKRoute?
    @State private var lookAroundScene: MKLookAroundScene?
    
    private let locationManager = CLLocationManager()

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedItem) {
            UserAnnotation()
            ForEach(fountains, id: \.self) { item in
                Marker(item: item)
                    .mapItemDetailSelectionAccessory(.callout)
            }
            if let mapRoute {
                MapPolyline(mapRoute)
                    .stroke(Color.blue, lineWidth: 5)
            }
        }
        .contentMargins(20)
        .overlay(alignment: .bottomLeading) {
            if lookAroundScene != nil {
                LookAroundPreview(scene: $lookAroundScene)
                    .frame(width: 230, height: 140)
                    .cornerRadius(10)
                    .padding(8)
            }
        }
        .onChange(of: selectedItem) {
            if let selectedItem {
                // Get a Look Around preview.
                Task {
                    let request = MKLookAroundSceneRequest(mapItem: selectedItem)
                    lookAroundScene = try? await request.scene
                }
                
                // Get cycling directions to the fountain.
                let request = MKDirections.Request()
                request.source = MKMapItem.forCurrentLocation()
                request.destination = selectedItem
                request.transportType = .cycling
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    guard let response else {
                        let logger = Logger()
                        logger.error("Error calculating directions: \(error!)")
                        return
                    }
                    if let route = response.routes.first {
                        mapRoute = route
                    }
                }
            } else {
                lookAroundScene = nil
                mapRoute = nil
            }
        }
        .onAppear {
            // This project is configured to simulate Dublin as the device location in the scheme options.
            locationManager.requestWhenInUseAuthorization()
        }
        .task {
            fountains = await DublinFountains.fountainMapItems()
        }
    }
}

#Preview {
    FountainMapView()
}
