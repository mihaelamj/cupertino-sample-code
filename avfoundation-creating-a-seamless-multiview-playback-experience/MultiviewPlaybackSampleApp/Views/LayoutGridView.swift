/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show players in an adjustable grid.
*/

import SwiftUI
import os

struct LayoutGridView: View {
    @Bindable var viewModel: LayoutGridViewModel
    @State var isInLayoutView: Bool
    
    @Binding var showAllControls: Bool
    
    // Show players in a flexible grid.
    @ViewBuilder
    var gridView: some View {
        VStack(spacing: 0.0) {
            ForEach(Array(0..<viewModel.numGridColumns), id: \.self) { column in
                HStack(spacing: 0.0) {
                    ForEach(Array(0..<viewModel.numGridRows), id: \.self) { row in
                        let index = (column * viewModel.numGridRows) + row
                        if index < viewModel.playersToShow.count {
                            // Show the player and autoplay.
                            PlayerView(playerState: viewModel.playersToShow[index],
                                       viewModel: viewModel,
                                       isInLayoutView: isInLayoutView,
                                       showAllControls: $showAllControls)
                                .onAppear {
                                    viewModel.playersToShow[index].play()
                                }.ignoresSafeArea()
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                gridView
            }
        }
    }
}
