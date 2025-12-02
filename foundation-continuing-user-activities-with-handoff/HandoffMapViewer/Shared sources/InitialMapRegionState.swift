/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration indicating if and how a map view's initially-displayed region has been set.
*/

import Foundation
import CoreLocation

/**
 An enumeration indicating if and how a map view's initially-displayed region has been set.
 */
enum InitialMapRegionState {
    /// The app has not yet set the map region.
    case notSet
    /// Launching from Handoff set the map region.
    case setFromHandoff
    /// Core Location used the current location to set the map region.
    case setFromCurrentLocation
    /// The app was launched from Handoff and is currently loading the map for a given store,
    /// after which it will set the map region.
    case loadingHandoffForStore(url: URL, coordinate: CLLocationCoordinate2D)
}

extension InitialMapRegionState: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .notSet:
            return "not set"
        case .setFromHandoff:
            return "set from Handoff"
        case .setFromCurrentLocation:
            return "set from current location"
        case .loadingHandoffForStore(let url, _):
            return "loading from Handoff for store (\(url.absoluteString))"
        }
    }
}
