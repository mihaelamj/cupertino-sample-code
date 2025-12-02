/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The list view component of the app's sidebar.
*/

import MapKit
import SwiftData
import SwiftUI

struct SidebarListView: View {
    
    @Environment(MapModel.self) private var mapModel
    @Environment(NavigationModel.self) private var navigationModel
    
    /// An environment variable indicating when the search interface is enabled.
    @Environment(\.isSearching) private var isSearching
    
    /// The data store that persists `VisitedPlace` instances across app launches.
    @Environment(\.modelContext) private var visitHistoryContext
    
    /// A query that returns only the most recent visited places from the model context.
    @Query(VisitedPlace.reverseOrderFetchDescriptor) var visitedPlaces: [VisitedPlace]
    
    /// An array of map items in the Visited Places section of the list.
    @State private var visitedMapItems: [MKMapItem] = []
    
    /// The text that displays at the top of the list to distinguish between search results and previously visited places.
    @State private var listTitle = "Visited Places"
    
    var body: some View {
        @Bindable var mapModel = mapModel
        
        List {
            let title = isSearching ? "Search Results" : "Visited Places"
            let sourceList = isSearching ? $mapModel.searchResults : $visitedMapItems
            
            SidebarListViewSection(mapItems: sourceList,
                                   sectionTitle: title)
        }
        .onChange(of: isSearching) { oldValue, isSearching in
            guard oldValue != isSearching else { return }
            
            if !isSearching {
                // Clear the search results when SwiftUI sets the `isSearching` variable in the environment to `false`.
                mapModel.searchResults = []
            }
        }
        .onChange(of: visitedPlaces, initial: true) {
            Task {
                // The `visitedPlaces` array stores the data across app launches, but the information
                // in `VisitedPlace` is not detailed enough to display in the UI without first converting
                // to a `MKMapItem`.
                var mapItems: [MKMapItem] = []
                for place in visitedPlaces {
                    if let mapItem = await place.convertToMapItem() {
                        mapItems.append(mapItem)
                    }
                }
                
                visitedMapItems = mapItems
            }
        }
        .onChange(of: mapModel.selectedMapItem) { _, newValue in
            if let mapItem = newValue {
                VisitedPlace.addNewVisit(mapItem: mapItem, to: visitHistoryContext)
            }
        }
        .task {
            // Place initial data into the model container so the sample is not empty when it runs for the first time.
            await VisitedPlace.seedHistoryWithInitialData(in: visitHistoryContext)
        }
    }
}
