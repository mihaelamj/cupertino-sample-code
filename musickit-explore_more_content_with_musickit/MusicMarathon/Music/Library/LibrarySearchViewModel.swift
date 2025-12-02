/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model class that holds music library search data.
*/

import Combine
import MusicKit
import SwiftUI

/// An object that performs a library search request when given a search term and holds the results.
class LibrarySearchViewModel: ObservableObject {
    
    // MARK: - Initialization
    
    init() {
        searchTermObserver = $searchTerm
            .sink(receiveValue: librarySearch)
    }
    
    // MARK: - Properties
    
    @Published var searchTerm = ""
    @Published var searchResponse: MusicLibrarySearchResponse?
    @Published var isDisplayingSuggestedPlaylists = false
    
    private var searchTermObserver: AnyCancellable?
    
    // MARK: - Methods
    
    /// Creates and performs a music library search when the search term changes.
    func librarySearch(for searchTerm: String) {
        if searchTerm.isEmpty {
            isDisplayingSuggestedPlaylists = true
            searchResponse = nil
        } else {
            Task {
                let librarySearchRequest = MusicLibrarySearchRequest(
                    term: searchTerm,
                    types: [
                        Song.self,
                        MusicVideo.self,
                        Album.self
                    ]
                )
                do {
                    let librarySearchResponse = try await librarySearchRequest.response()
                    await self.update(with: librarySearchResponse, for: searchTerm)
                } catch {
                    print("Failed to load library search results due to error: \(error).")
                }
            }
        }
    }
    
    /// Safely updates the `searchResponse` on the main thread.
    @MainActor
    func update(with libraryResponse: MusicLibrarySearchResponse, for searchTerm: String) {
        if self.searchTerm == searchTerm {
            self.searchResponse = libraryResponse
        }
    }
}
