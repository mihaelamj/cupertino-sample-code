/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A single section in the app's sidebar list.
*/

import MapKit
import SwiftUI

/// A collection of map items in the app's sidebar.
struct SidebarListViewSection: View {
    
    @Binding var mapItems: [MKMapItem]
    let sectionTitle: String
    
    var body: some View {
        Section(sectionTitle) {
            // Treat each `MKMapItem` object as unique, using `\.self` for the identity. The `identifier` property of `MKMapItem`
            // is an optional value, and the meaning of the identifier for `MKMapItem` doesn't have the same semantics as
            // the `Identifable` protocol that `ForEach` requires.
            ForEach($mapItems, id: \.self) { mapItem in
                SidebarListItem(mapItem: mapItem.wrappedValue)
            }
        }
    }
}
