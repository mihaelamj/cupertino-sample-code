/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays radio station information.
*/

import MusicKit
import SwiftUI

/// A cell that isplays radio station information.
struct StationCell: View {
    
    // MARK: - Initialization
    
    init(_ station: Station) {
        self.station = station
    }
    
    // MARK: - Properties
    
    let station: Station
    
    // MARK: - View
    
    var body: some View {
        MusicItemCell(
            artwork: station.artwork,
            title: station.name,
            subtitle: station.stationProviderName
        )
    }
}
