/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show players in an adjustable layout.
*/

import SwiftUI

struct LayoutView: View {
    @Bindable var viewModel: LayoutGridViewModel
    @State var showAllControls = false
    let isInLayoutView = true
    
    // Show the buttons for each URL of the menu items to add players to the view.
    @ViewBuilder
    var playerSelectionView: some View {
        // Iterate through rows and columns.
        ScrollView(.horizontal) {
            HStack {
                if showAllControls {
                    ForEach(0..<viewModel.selectedItemAssets.count, id: \.self) { index in
                        // Add a player to the view.
                        Button {
                            viewModel.addPlayerToLayout(asset: viewModel.selectedItemAssets[index])
                        } label: {
                            Text("\(viewModel.selectedItemAssets[index].name)")
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(SelectionButtonStyle())
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            LayoutGridView(viewModel: viewModel, isInLayoutView: isInLayoutView, showAllControls: $showAllControls)
#if os(tvOS)
                .focusSection()
#endif
            VStack {
                Spacer()
                PlaybackControlsView(viewModel: viewModel, showAllControls: $showAllControls)
                HStack {
                    playerSelectionView
                }
    #if os(tvOS)
                .focusSection()
    #endif
            }
            
        }
        .background(.black)
    }
}

