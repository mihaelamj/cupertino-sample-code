/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays radio show information.
*/

import MusicKit
import SwiftUI

/// A  cell that displays information about a radio show.
struct RadioShowCell: View {
    
    // MARK: - Initialization
    
    init(_ radioShow: RadioShow) {
        self.radioShow = radioShow
    }
    
    // MARK: - Properties
    
    let radioShow: RadioShow
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: RadioShowDetailView(radioShow: radioShow)) {
            MusicItemCell(
                artwork: radioShow.artwork,
                title: radioShow.name,
                subtitle: radioShow.hostName
            )
        }
    }
    
}
