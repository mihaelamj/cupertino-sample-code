/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to show the PlayerViewController.
*/

import SwiftUI
import AVFoundation

struct PlayerView: View {
    let playerState: PlayerState
    let viewModel: LayoutGridViewModel
    let isInLayoutView: Bool
    @Binding var showAllControls: Bool
    
    @ViewBuilder
    var layoutControlsView: some View {
        VStack {
            HStack {
#if os(iOS)
                Spacer()
#endif
                
                // Focus the player.
                Button {
                    viewModel.setFocusOnPlayer(playerID: playerState.playerID)
                } label: {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.focusPlayerID == playerState.playerID ? .yellow : .white)
                }
                .buttonStyle(SelectionButtonStyle())
                
                // Set the player to display in full screen.
                Button {
                    viewModel.setFullScreenPlayer(playerState: playerState)
                } label: {
                    Image(systemName: playerState.isFullScreen ? "arrow.up.right.and.arrow.down.left" : "arrow.down.left.and.arrow.up.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .buttonStyle(SelectionButtonStyle())
                
                // Remove the player.
                if isInLayoutView && playerState.isFullScreen == false {
                    Button {
                        viewModel.removePlayerFromLayout(playerID: playerState.playerID)
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(SelectionButtonStyle())
                }
                
                Spacer()
            }
            .padding(Edge.Set(Edge.top), 50)
            
            Spacer()
        }
    }
    
    var body: some View {
        
        if !playerState.shouldBeHidden {
            ZStack {
                // Show the player.
                PlayerViewController(playerState: playerState)
                    .focusable(false)
                
                // Show the layout control buttons.
                if showAllControls {
                    layoutControlsView
                }
            }
        }
    }
}
