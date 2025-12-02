/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The annotation data object representing all types of cycles.
*/

import MapKit

class Cycle: NSObject, Decodable, MKAnnotation {
    
    enum CycleType: Int, Decodable {
        case unicycle
        case bicycle
        case tricycle
    }
    
    var type: CycleType = .unicycle
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            // For most uses, `coordinate` can be a standard property declaration without the customized getter and setter shown here.
            // The custom getter and setter are needed in this case because of how it loads data from the `Decodable` protocol.
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}
