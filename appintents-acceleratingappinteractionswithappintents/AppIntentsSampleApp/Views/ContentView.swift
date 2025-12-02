/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the app.
*/

import SwiftUI

struct ContentView: View {
    
    @Environment(NavigationModel.self) private var navigationModel
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        NavigationSplitView(columnVisibility: $navigationModel.columnVisibility, preferredCompactColumn: $navigationModel.preferredCompactColumn) {
            SidebarColumn()
                .navigationSplitViewColumnWidth(min: 200, ideal: 350)
        } content: {
            TrailList()
        } detail: {
            TrailDetailColumn()
        }
        .sheet(isPresented: $navigationModel.displayInProgressActivityInfo) {
            ActiveActivityInfoView()
            #if !os(watchOS)
                .frame(minWidth: 300, minHeight: 200)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            #endif
        }
    }
}
