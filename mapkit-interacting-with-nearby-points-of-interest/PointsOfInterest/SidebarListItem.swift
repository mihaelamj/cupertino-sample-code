/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays a description of a map item in the app's sidebar.
*/

import MapKit
import SwiftUI

struct SidebarListItem: View {
    
    @Environment(NavigationModel.self) private var navigationModel
    
    /// The map item that this item represents in the sidebar.
    let mapItem: MKMapItem
    
    /// A state variable controlling when to present the details for a map item.
    @State private var mapItemCalloutPresented = false
    
    var body: some View {
        Button {
            mapItemCalloutPresented = true
        } label: {
            MapItemRowView(mapItem: mapItem)
        }
        // When people tap on the item, the app presents additional details about it, either as a popover or as a
        // sheet when a view is in a compact environment. Alternatively, the `mapItemDetailSheet(isPresetned:item:displaysMap)`
        // modifier always uses a sheet presentation style.
        .mapItemDetailPopover(isPresented: $mapItemCalloutPresented, item: mapItem, displaysMap: displayMapOnDetailView)
    }
    
    private var displayMapOnDetailView: Bool {
        /*
         When the `NavigationSplitView` collapses its interface and shows only the sidebar column,
         the app's main `MapView` isn't visible, so include a map in the detail popover to give
         the person context for the location.
         */
        navigationModel.preferredCompactColumn == .sidebar
    }
}
