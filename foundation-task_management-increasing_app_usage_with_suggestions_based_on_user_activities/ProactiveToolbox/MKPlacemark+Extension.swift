/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper extension for formatting an address for display.
*/

import Contacts
import MapKit

extension MKPlacemark {
    
    var formattedAddress: String? {
        guard let postalAddress = postalAddress
            else { return nil }
        
        let mailingAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
        return mailingAddress.replacingOccurrences(of: "\n", with: " ")
    }
}
