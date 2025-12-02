/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure representing an Apple Store on a map.
*/

import Foundation
import MapKit
import CoreLocation
import Contacts

/**
 A structure representing an Apple Store on a map.
 */
struct AppleStore {
    /// The name of the Apple Store, like "Apple Store Woodland".
    let name: String
    /// A placemark indicating the store's location on a map.
    let placemark: MKPlacemark
    /// The URL of the store, like http://www.apple.com/retail/woodland.
    let url: URL
    
    /**
     Creates an AppleStore from the MKMapItem, provided the name and url indicate that it
     is an Apple Store location.
     */
    init?(from mapItem: MKMapItem) {
        guard let name = mapItem.name,
            let url = mapItem.url,
            let host = mapItem.url?.host,
            let path = mapItem.url?.path,
            (host.starts(with: "www.apple.com") || host.starts(with: "apple.com")) && path.contains("retail") else {
                return nil
        }
        
        self.name = name
        self.placemark = mapItem.placemark
        self.url = url
    }
}

// MARK: Hashable/Set support
extension AppleStore: Hashable, Equatable {
    
    /// The hashValue uses the name and URL only.
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(url)
    }
    
    /// Two stores are equal if the name and URL of both instances are equal.
    static func ==(lhs: AppleStore, rhs: AppleStore) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url
    }
}

extension AppleStore: CustomDebugStringConvertible {
    var debugDescription: String {
        guard let address = placemark.postalAddress  else { return "Apple Store" }
        return "\(name) @\(address.subLocality) \(address.street), \(address.city), \(address.state)"
    }
}
