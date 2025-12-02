/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that implements search.
*/

import MusicKit
import SwiftUI

/// A view the displays recommended playlists and catalog search results when the user enters a term.
struct SearchView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SearchViewModel()
    
    // MARK: - View
    
    var body: some View {
        VStack {
            navigationView
                .onAppear(perform: viewModel.loadRecommendedPlaylists)
        }
    }
    
    private var navigationView: some View {
        NavigationView {
            navigationPrimaryView
                .navigationTitle("Catalog")
        }
        .searchable(text: $viewModel.searchTerm)
    }
    
    private var navigationPrimaryView: some View {
        VStack(alignment: .leading) {
            itemsList
                .resignKeyboardOnDragGesture()
        }
    }
    
    @ViewBuilder
    private var itemsList: some View {
        List {
            if let searchResponse = viewModel.searchResponse {
                ForEach(searchResponse.suggestions, id: \.self) { suggestion in
                    Text(suggestion.displayTerm)
                        .onTapGesture {
                            viewModel.searchTerm = suggestion.displayTerm
                        }
                }

                MusicItemSection(title: "Top Results", items: searchResponse.topResults) { topResult in
                    topResultCell(for: topResult)
                }
                
            } else {
                Section(header: Text("Personal Recommendations").fontWeight(.semibold)) {
                    ForEach(viewModel.recommendedPlaylists) { playlist in
                        PlaylistCell(playlist)
                    }
                }
            }
        }
        .animation(.default, value: viewModel.recommendedPlaylists)
        .animation(.default, value: viewModel.searchResponse)
    }
    
    @ViewBuilder
    func topResultCell(for topResult: MusicCatalogSearchResponse.TopResult) -> some View {
        switch topResult {
            case .album(let album):
                AlbumCell(album)
            case .artist(let artist):
                ArtistCell(artist)
            case .curator(let curator):
                CuratorCell(curator)
            case .musicVideo(let musicVideo):
                TrackCell(.musicVideo(musicVideo))
            case .playlist(let playlist):
                PlaylistCell(playlist)
            case .radioShow(let radioShow):
                RadioShowCell(radioShow)
            case .song(let song):
                TrackCell(.song(song))
            default:
                EmptyView()
        }
    }
}

