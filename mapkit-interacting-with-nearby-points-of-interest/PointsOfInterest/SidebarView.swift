/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sidebar view, responsible for managing the search state.
*/

import MapKit
import SwiftUI

struct SidebarView: View {
    @Environment(MapModel.self) private var mapModel
    @Environment(LocationService.self) private var locationService
    @Environment(NavigationModel.self) private var navigationModel
    
    /// The query in the search bar.
    @State private var searchQuery = ""
    
    /// The current completions that MapKit provides.
    @State private var searchCompletions: [MKLocalSearchCompletion] = []
    
    @State private var showingSettingsMenu = false
    
    /// - Tag: SidebarView
    var body: some View {
        @Bindable var mapModel = mapModel
        
        SidebarListView()
        .navigationTitle("Search")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingSettingsMenu = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .popover(isPresented: $showingSettingsMenu) {
                    SettingsView(locationService: locationService, searchConfiguration: mapModel.searchConfiguration)
                        .frame(minWidth: 375, minHeight: 450)
                }
                if navigationModel.preferredCompactColumn != .detail {
                    Button {
                        navigationModel.preferredCompactColumn = .detail
                    } label: {
                        Label("Show Map", systemImage: "map")
                    }
                }
            }
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: searchPrompt)
        .searchSuggestions {
            // Treat each `MKMapItem` object as unique, using `\.self` for the identity. The `identifier` property of `MKMapItem`
            // is an optional value, and the meaning of the identifier for `MKMapItem` doesn't have the same semantics as
            // the `Identifable` protocol that `ForEach` requires.
            ForEach($searchCompletions, id: \.self) { completion in
                SearchCompletionItemView(completion: completion.wrappedValue)
                .onTapGesture {
                    convertSearchCompletionToSearchResults(completion.wrappedValue)
                }
            }
        }
        .onSubmit(of: .search) {
            Task {
                // This system calls this method when a person taps Search on the keyboard.
                // Because the user hasn't selected a row with a suggested completion, run the search with the query text in the search field.
                let searchResults = await mapModel.searchDataSource.search(for: searchQuery)
                mapModel.searchResults = searchResults
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            /*
             The search query property updates frequently, based on each keystroke the person makes in the search field. By
             requesting new completion suggestions after every keystroke, the app UI can show suggestions
             that allows the person to quickly get to their intended search string without having to type it in its entirety.
            */
            mapModel.searchDataSource.provideCompletionSuggestions(for: newValue)
            
            // Clear the search results becuase the person has changed the query string. The updated query string may not match the existing search
            // results or the new suggested completions.
            mapModel.searchResults = []
        }
        .onAppear {
            startProvidingSearchCompletions()
        }
        .onDisappear {
            stopProvidingSearchCompletions()
        }
    }
    
    private var searchPrompt: LocalizedStringKey {
        switch mapModel.searchConfiguration.resultType {
        case .addresses:
            "Addresses"
        case .pointsOfInterest:
            "Points of Interest"
        }
    }
    
    /// Perform a search with the completion, and display the results in the UI.
    private func convertSearchCompletionToSearchResults(_ completion: MKLocalSearchCompletion) {
        /*
         To keep the UI reflecting the correct state, change the text of the search field to reflect the selected completion.
         To prevent this change from generating new completions, pause getting updated completions until the search results display.
         */
        stopProvidingSearchCompletions()
        searchQuery = completion.title
        
        Task {
            let searchResults = await mapModel.searchDataSource.search(for: completion)
            mapModel.searchResults = searchResults
            
            // After the UI updates the search results, restart generating search completions for further modificaitons of the search text.
            startProvidingSearchCompletions()
        }
    }
    
    /// Request that the data source generate search completions based on what the person types into the search field, so that they don't
    /// need to type their entire search query.
    private func startProvidingSearchCompletions() {
        Task { @MainActor in
            // Receive the search completions through an `AsyncStream` that search data source manages.
            let searchCompletionStream = AsyncStream<[MKLocalSearchCompletion]>.makeStream()
            mapModel.searchDataSource.startProvidingSearchCompletions(with: searchCompletionStream.continuation)
            
            for await completions in searchCompletionStream.stream {
                searchCompletions = completions
            }
        }
    }
    
    /// This object stops listening for search completions and no longer displays them in the UI.
    private func stopProvidingSearchCompletions() {
        mapModel.searchDataSource.stopProvidingSearchCompletions()
        searchCompletions = []
    }
}
