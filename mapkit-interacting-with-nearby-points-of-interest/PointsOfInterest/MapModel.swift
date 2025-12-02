/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object containing shared state for configuring a map and associated views.
*/

import Foundation
import MapKit
import SwiftUI

@MainActor
@Observable class MapModel {
    
    /// The parameters to use for a search.
    var searchConfiguration: MapSearchConfiguration
    
    /// The object that manages search queries.
    var searchDataSource: SearchDataSource
    
    /// An array of search results based on a query, representing the full information available for the map item, including its name,
    /// its location, and its cateogry, such as a hotel or a restaurant.
    var searchResults: [MKMapItem] = []
    
    /// The item selected in the `MapView`.
    var selectedMapItem: MKMapItem?
    
    init() {
        let configuration = MapSearchConfiguration()
        searchConfiguration = configuration
        searchDataSource = SearchDataSource(configuration: configuration)
    }
}
