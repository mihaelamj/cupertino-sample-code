/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that holds the watchOS app's visual content.
*/

import SwiftUI
import SwiftData
import BackyardBirdsData
import BackyardBirdsUI

struct ContentView: View {
    @Query(sort: \.creationDate)
    private var backyards: [Backyard]
    
    var body: some View {
        NavigationSplitView {
            BackyardList()
                .navigationTitle("Backyard Birds")
                .navigationDestination(for: Backyard.ID.self) { backyardID in
                    if let backyard = backyards.first(where: { $0.id == backyardID }) {
                        BackyardTabView(backyard: backyard)
                    }
                }
        } detail: {
            ContentUnavailableView("Select a Backyard", systemImage: "bird", description: Text("Pick something from the list."))
        }
    }
}

#Preview {
    ContentView()
        .backyardBirdsDataContainer(inMemory: true)
}
