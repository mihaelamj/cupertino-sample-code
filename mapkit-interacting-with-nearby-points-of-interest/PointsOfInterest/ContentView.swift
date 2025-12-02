/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The outermost view of the scene that defines the container views and environment objects that the subviews need.
*/

import SwiftUI

struct ContentView: View {
    
    @State private var mapModel = MapModel()
    @State private var navigationModel = NavigationModel()
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        
        NavigationSplitView(columnVisibility: $navigationModel.columnVisibility, preferredCompactColumn: $navigationModel.preferredCompactColumn) {
            SidebarView()
                .modelContainer(for: [VisitedPlace.self])
        } detail: {
            MapView()
                .navigationTitle("Explore")
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(mapModel)
        .environment(navigationModel)
    }
}
