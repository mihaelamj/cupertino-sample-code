/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom MKAnnotation object representing the Golden Gate Bridge.
*/

import UIKit
import MapKit

class BridgeAnnotation: NSObject, MKAnnotation {
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate = CLLocationCoordinate2D(latitude: 37.810_000, longitude: -122.477_450)
    
    // Required if you set the annotation view's `canShowCallout` property to `true`
    var title: String? = NSLocalizedString("BRIDGE_TITLE", comment: "Bridge annotation")
    
    // This property defined by `MKAnnotation` is not required.
    var subtitle: String? = NSLocalizedString("BRIDGE_SUBTITLE", comment: "Bridge annotation")
}
