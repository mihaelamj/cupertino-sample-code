/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model object that holds recently played songs.
*/

import Combine
import MusicKit
import SwiftUI

/// A data model object that fetches the user's recently played music items.
/// This object also offers a convenient way to observe recently played music items.
class RecentlyPlayedViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// A collection of recently played items.
    @Published var recentlyPlayedItems: MusicItemCollection<RecentlyPlayedMusicItem> = []
    
    /// Observes changes to the current MusicKit authorization status.
    private var musicAuthorizationStatusObserver: AnyCancellable?
    
    // MARK: - Methods
    
    /// Begins observing MusicKit authorization status.
    func beginObservingMusicAuthorizationStatus() {
        musicAuthorizationStatusObserver = WelcomeView.PresentationCoordinator.shared.$musicAuthorizationStatus
            .filter { authorizationStatus in
                return (authorizationStatus == .authorized)
            }
            .sink { [weak self] _ in
                self?.loadRecentlyPlayedItems()
            }
    }
    
    /// Fetches the recently played items when the MusicKit authorization status changes.
    private func loadRecentlyPlayedItems() {
        Task {
            do {
                let recentlyPlayedRequest = MusicRecentlyPlayedContainerRequest()
                let recentlyPlayedResponse = try await recentlyPlayedRequest.response()
                await self.updateRecentlyPlayedItems(recentlyPlayedResponse.items)
            } catch {
                print("Failed to load suggested playlists due to error: \(error).")
            }
        }
    }
    
    /// Safely changes the `recentlyPlayedItems` on the main thread.
    @MainActor
    private func updateRecentlyPlayedItems(_ items: MusicItemCollection<RecentlyPlayedMusicItem>) {
        recentlyPlayedItems = items
    }
}
