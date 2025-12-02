/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view that allows users to find music they want to rediscover.
*/

import MusicKit
import SwiftUI

struct ContentView: View {
    
    // MARK: - View
    
    var body: some View {
        rootView
            .onAppear(perform: recentAlbumsStorage.beginObservingMusicAuthorizationStatus)
            .onChange(of: searchTerm, perform: requestUpdatedSearchResults)
            .onChange(of: detectedBarcode, perform: handleDetectedBarcode)
            .onChange(of: isDetectedAlbumDetailViewActive, perform: handleDetectedAlbumDetailViewActiveChange)
        
            // Display the barcode scanning view when appropriate.
            .sheet(isPresented: $isBarcodeScanningViewPresented) {
                BarcodeScanningView($detectedBarcode)
            }
        
            // Display the development settings view when appropriate.
            .sheet(isPresented: $isDevelopmentSettingsViewPresented) {
                DevelopmentSettingsView()
            }
        
            // Display the welcome view when appropriate.
            .welcomeSheet()
    }
    
    /// The various components of the main navigation view.
    private var navigationViewContents: some View {
        VStack {
            searchResultsList
                .animation(.default, value: albums)
            if isBarcodeScanningAvailable {
                if albums.isEmpty {
                    Button(action: { isBarcodeScanningViewPresented = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60, weight: .semibold))
                    }
                }
                if let albumMatchingDetectedBarcode = detectedAlbum {
                    NavigationLink(destination: AlbumDetailView(albumMatchingDetectedBarcode), isActive: $isDetectedAlbumDetailViewActive) {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    /// The top-level content view.
    private var rootView: some View {
        NavigationView {
            navigationViewContents
                .navigationTitle("Music Albums")
        }
        .searchable(text: $searchTerm, prompt: "Albums")
        .gesture(hiddenDevelopmentSettingsGesture)
    }
    
    // MARK: - Search results requesting
    
    /// The current search term the user enters.
    @State private var searchTerm = ""
    
    /// The albums the app loads using MusicKit that match the current search term.
    @State private var albums: MusicItemCollection<Album> = []
    
    /// A reference to the storage object for recent albums the user previously viewed in the app.
    @StateObject private var recentAlbumsStorage = RecentAlbumsStorage.shared
    
    /// A list of albums to display below the search bar.
    private var searchResultsList: some View {
        List(albums.isEmpty ? recentAlbumsStorage.recentlyViewedAlbums : albums) { album in
            AlbumCell(album)
        }
    }
    
    /// Makes a new search request to MusicKit when the current search term changes.
    private func requestUpdatedSearchResults(for searchTerm: String) {
        Task {
            if searchTerm.isEmpty {
                self.reset()
            } else {
                do {
                    // Issue a catalog search request for albums matching the search term.
                    var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                    searchRequest.limit = 5
                    let searchResponse = try await searchRequest.response()
                    
                    // Update the user interface with the search response.
                    self.apply(searchResponse, for: searchTerm)
                } catch {
                    print("Search request failed with error: \(error).")
                    self.reset()
                }
            }
        }
    }
    
    /// Safely updates the `albums` property on the main thread.
    @MainActor
    private func apply(_ searchResponse: MusicCatalogSearchResponse, for searchTerm: String) {
        if self.searchTerm == searchTerm {
            self.albums = searchResponse.albums
        }
    }
    
    /// Safely resets the `albums` property on the main thread.
    @MainActor
    private func reset() {
        self.albums = []
    }
    
    // MARK: - Barcode detection handling
    
    /// `true` if the barcode scanning functionality is available to the user.
    @AppStorage("barcode-scanning-available") private var isBarcodeScanningAvailable = true
    
    /// `true` if the content view needs to display the barcode scanning view.
    @State private var isBarcodeScanningViewPresented = false
    
    /// A barcode that the barcode scanning view detects.
    @State private var detectedBarcode = ""
    
    /// The album that matches the detected barcode, if any.
    @State private var detectedAlbum: Album?
    
    /// `true` if the content view needs to display the album detail view.
    @State private var isDetectedAlbumDetailViewActive = false
    
    /// Searches for an album that matches a barcode that the barcode scanning view detects.
    private func handleDetectedBarcode(_ detectedBarcode: String) {
        if detectedBarcode.isEmpty {
            self.detectedAlbum = nil
        } else {
            Task {
                do {
                    let albumsRequest = MusicCatalogResourceRequest<Album>(matching: \.upc, equalTo: detectedBarcode)
                    let albumsResponse = try await albumsRequest.response()
                    if let firstAlbum = albumsResponse.items.first {
                        self.handleDetectedAlbum(firstAlbum)
                    }
                } catch {
                    print("Encountered error while trying to find albums with upc = \"\(detectedBarcode)\".")
                }
            }
        }
    }
    
    /// Safely updates state properties on the main thread.
    @MainActor
    private func handleDetectedAlbum(_ detectedAlbum: Album) {
        
        // Dismiss the barcode scanning view.
        self.isBarcodeScanningViewPresented = false
        
        // Push the album detail view for the detected album.
        self.detectedAlbum = detectedAlbum
        withAnimation {
            self.isDetectedAlbumDetailViewActive = true
        }
        
    }
    
    /// Clears the scanned barcode when hiding or showing the album detail view.
    private func handleDetectedAlbumDetailViewActiveChange(_ isDetectedAlbumDetailViewActive: Bool) {
        if !isDetectedAlbumDetailViewActive {
            self.detectedBarcode = ""
        }
    }
    
    // MARK: - Development settings
    
    /// `true` if the content view needs to display the development settings view.
    @State var isDevelopmentSettingsViewPresented = false
    
    /// A custom gesture that initiates the presentation of the development settings view.
    private var hiddenDevelopmentSettingsGesture: some Gesture {
        TapGesture(count: 3).onEnded {
            isDevelopmentSettingsViewPresented = true
        }
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
