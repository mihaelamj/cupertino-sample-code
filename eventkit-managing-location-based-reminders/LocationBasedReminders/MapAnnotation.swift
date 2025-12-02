/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom map annotation to represent a generic location.
*/

import CoreLocation
import MapKit

struct MapAnnotation: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let coordinates: Coordinates
    let name: String
    
    init(id: Int, coordinate: Coordinates, name: String) {
        self.id = id
        self.coordinates = coordinate
        self.name = name
    }
}

extension MapAnnotation {
    var location: CLLocation {
        CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
    }
}

extension MapAnnotation: Equatable {
    static func == (lhs: MapAnnotation, rhs: MapAnnotation) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinates == rhs.coordinates &&
        lhs.name == rhs.name
    }
}

struct Coordinates: Hashable, Codable, Sendable {
    let latitude: Double
    let longitude: Double
}
