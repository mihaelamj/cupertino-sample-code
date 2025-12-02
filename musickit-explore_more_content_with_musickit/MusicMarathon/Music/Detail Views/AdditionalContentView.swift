/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays additional content about the selected item.
*/

import MusicKit
import SwiftUI

/// A view that loads and displays additional items for a given music item.
struct AdditionalContentView<MusicItemType>: View
                                           where MusicItemType: MusicItem,
                                                 MusicItemType: Decodable,
                                                 MusicItemType: Equatable,
                                                 MusicItemType: Identifiable {
    
    // MARK: - Properties
    
    @State var items: MusicItemCollection<MusicItemType>
    let title: String
    
    @State private var isLoadingAdditionalContent = false
    @State private var hasCompletedFirstRequest = false
    
    // MARK: - View
    
    var body: some View {
        content
            .onAppear {
                if items.hasNextBatch {
                    handleLoadMoreButtonSelection()
                }
            }
    }
    
    private var content: some View {
        contentScrollingList
            .navigationTitle(title)
    }
    
    private var contentScrollingList: some View {
        ScrollViewReader { scrollViewProxy in
            contentList
                .onChange(of: items) { [items] updatedItems in
                    if updatedItems.count > items.count {
                        if !hasCompletedFirstRequest {
                            hasCompletedFirstRequest = true
                        } else if let previousLastItem = items.last {
                            withAnimation {
                                scrollViewProxy.scrollTo(previousLastItem.id, anchor: .top)
                            }
                        }
                    }
                }
        }
    }
    
    private var contentList: some View {
        List {
            ForEach(items) { item in
                if let song = item as? Song {
                    TrackCell(.song(song))
                } else if let album = item as? Album {
                    AlbumCell(album)
                } else if let playlist = item as? Playlist {
                    PlaylistCell(playlist)
                } else if let artist = item as? Artist {
                    ArtistCell(artist)
                } else if let musicVideo = item as? MusicVideo {
                    TrackCell(.musicVideo(musicVideo))
                }
            }
            if items.hasNextBatch {
                loadMoreButton
                    .disabled(isLoadingAdditionalContent)
            }
        }
    }
    
    private var loadMoreButton: some View {
        Button(action: handleLoadMoreButtonSelection) {
            Text("Load More")
        }
    }
    
    // MARK: - Selection handling
    
    private func handleLoadMoreButtonSelection() {
        isLoadingAdditionalContent = true
        Task {
            do {
                let nextBatchItems = try await items.nextBatch(limit: 6)
                await self.appendItems(from: (nextBatchItems ?? []))
            } catch {
                await self.handleIncrementalLoadingFailure(with: error)
            }
        }
    }
    
    @MainActor
    private func appendItems(from nextBatchItems: MusicItemCollection<MusicItemType>) {
        withAnimation {
            items += nextBatchItems
            isLoadingAdditionalContent = false
        }
    }
    
    @MainActor
    private func handleIncrementalLoadingFailure(with error: Error) {
        print("Incremental content request failed with error: \(error).")
        withAnimation {
            if let dataRequestError = error as? MusicDataRequest.Error, dataRequestError.status == 404 {
                items += []
            }
            isLoadingAdditionalContent = false
        }
    }
    
}
