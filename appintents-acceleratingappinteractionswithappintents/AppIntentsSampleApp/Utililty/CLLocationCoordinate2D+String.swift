/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility file for location coordinates.
*/

import CoreLocation
import Foundation

extension CLLocationCoordinate2D {
    var formattedDisplayValue: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 6
        
        guard let latitudeString = numberFormatter.string(from: NSNumber(value: latitude)),
              let longitudeString = numberFormatter.string(from: NSNumber(value: longitude)) else {
                  return "Invalid Coordinate"
              }
        
        return "\(latitudeString), \(longitudeString)"
    }
}
