/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to display the player playback controls.
*/

import SwiftUI

struct PlaybackControlsView: View {
    @Bindable var viewModel: LayoutGridViewModel
    @Binding var showAllControls: Bool
    
    var body: some View {
        VStack {
#if os(iOS)
            HStack {
                // Hide or show all controls.
                Button {
                    showAllControls = !showAllControls
                } label: {
                    Image(systemName: showAllControls ? "eye.slash" : "eye")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .buttonStyle(SelectionButtonStyle())
                
                Spacer()
            }
            
            Spacer()
#endif
            
            HStack(spacing: 4.0) {
#if os(tvOS)
                // Hide or show all controls.
                Button {
                    showAllControls = !showAllControls
                } label: {
                    Image(systemName: showAllControls ? "eye.slash" : "eye")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .buttonStyle(SelectionButtonStyle())
                
                Spacer()
#endif
        
                if showAllControls {
                    // Seek backward by 10 seconds.
                    Button {
                        viewModel.playersToShow[viewModel.focusPlayerIndex].seek(by: -10)
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(SelectionButtonStyle())
                    
                    Spacer()
                    
                    // Play or pause the player.
                    Button {
                        if viewModel.playersToShow[viewModel.focusPlayerIndex].playerRate == 0 {
                            viewModel.playersToShow[viewModel.focusPlayerIndex].play()
                        } else {
                            viewModel.playersToShow[viewModel.focusPlayerIndex].pause()
                        }
                    } label: {
                        if !viewModel.playersToShow.isEmpty {
                            Image(systemName: viewModel.playersToShow[viewModel.focusPlayerIndex].playerRate == 0 ? "play.fill" : "pause.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(SelectionButtonStyle())
                    
                    Spacer()
                    
                    // Seek forward by 10 seconds.
                    Button {
                        viewModel.playersToShow[viewModel.focusPlayerIndex].seek(by: 10)
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(SelectionButtonStyle())
                } else {
                    Spacer()
                }
            }

#if os(iOS)
            Spacer()
#endif
        }

    }
}
