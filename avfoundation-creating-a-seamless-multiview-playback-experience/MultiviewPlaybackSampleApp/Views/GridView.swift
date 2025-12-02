/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show players in a fixed grid.
*/

import Foundation
import SwiftUI
import AVFoundation
import os

struct GridView: View {
    @Bindable var viewModel: LayoutGridViewModel
    @State var showAllControls = false
    let isInLayoutView = false
    
    var body: some View {
        ZStack {
            // Show the grid of players.
            LayoutGridView(viewModel: viewModel, isInLayoutView: isInLayoutView, showAllControls: $showAllControls)
                .background(.black)
                .onAppear {
                    if viewModel.playersToShow.isEmpty {
                        viewModel.createAllPlayers()
                    }
                }
                #if os(tvOS)
                .focusSection()
                #endif
            
            // Show the playback controls for the players.
            PlaybackControlsView(viewModel: viewModel, showAllControls: $showAllControls)
            #if os(tvOS)
                .focusSection()
            #endif
        }
    }
}
