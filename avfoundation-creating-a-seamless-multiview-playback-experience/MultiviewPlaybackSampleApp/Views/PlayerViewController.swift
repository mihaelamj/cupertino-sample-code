/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to display player content and its interface.
*/

import SwiftUI
import AVFoundation
import AVKit
import os

struct PlayerViewController: UIViewControllerRepresentable {
    let playerState: PlayerState
    
    public init(playerState: PlayerState) {
        self.playerState = playerState
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerController = AVPlayerViewController()
        
        playerController.showsPlaybackControls = false
        
        // Set the player.
        playerController.player = playerState.player
        playerController.allowsPictureInPicturePlayback = true
        
        return playerController
    }
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {
#if !os(tvOS)
        playerController.canStartPictureInPictureAutomaticallyFromInline = playerState.isFocusPlayer
        playerController.updatesNowPlayingInfoCenter = playerState.isFocusPlayer
#endif
    }
}
