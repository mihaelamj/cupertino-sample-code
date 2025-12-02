/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model object that represents a landmark.
*/

import CoreLocation
import MapKit

struct Landmark: Hashable, Codable, Identifiable {
    var id: Int
    var name: String
    var continent: String
    var description: String
    var latitude: Double
    var longitude: Double
    var span: Double
    var placeID: String?
    
    var backgroundImageName: String {
        return "\(id)"
    }
    
    var thumbnailImageName: String {
        return "\(id)-thumb"
    }
    
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude)
    }
    
    var coordinateRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: locationCoordinate,
                           span: .init(latitudeDelta: span, longitudeDelta: span))
    }

    var formattedCoordinates: String {
        String(localized: "\(latitude.formatted())\n\(longitude.formatted())",
               comment: "The coordinates of a landmark, consisting of the latitude and longitude")
    }
}
