/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays recently played songs.
*/

import MusicKit
import SwiftUI

/// A cell that displays recently played music items.
struct RecentlyPlayedCell: View {
    
    // MARK: - Initialization
    
    init(_ recentlyPlayedItem: RecentlyPlayedMusicItem) {
        self.recentlyPlayedItem = recentlyPlayedItem
    }
    
    // MARK: - Properties
    
    let recentlyPlayedItem: RecentlyPlayedMusicItem
    
    // MARK: - View
    
    var body: some View {
        switch recentlyPlayedItem {
            case .album(let album):
                AlbumCell(album)
                    .recentlyPlayedCellStyle()
                
            case .playlist(let playlist):
                PlaylistCell(playlist)
                    .recentlyPlayedCellStyle()
                
            case .station(let station):
                StationCell(station)
                    .recentlyPlayedCellStyle()
                
            @unknown default:
                EmptyView()
        }
    }
}

// MARK: - Cell design helper

struct RecentlyPlayedCellStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .standardShadow()
            }
    }
}

extension View {
    func recentlyPlayedCellStyle() -> some View {
        return modifier(RecentlyPlayedCellStyle())
    }
}

