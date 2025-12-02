/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures representing the map's location and data.
*/

import MapKit
import CoreLocation

struct MapData: Decodable {
    let cycles: [Cycle]

    let centerLatitude: CLLocationDegrees
    let centerLongitude: CLLocationDegrees
    let latitudeDelta: CLLocationDegrees
    let longitudeDelta: CLLocationDegrees

    var region: MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        return MKCoordinateRegion(center: center, span: span)
    }
}
