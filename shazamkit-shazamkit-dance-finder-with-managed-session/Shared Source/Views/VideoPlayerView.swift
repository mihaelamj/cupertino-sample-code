/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom view for a video player used to play a dance video after a match.
*/
import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    
    @Binding var player: AVPlayer
    
    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        
        @Binding var player: AVPlayer
        
        init(player: Binding<AVPlayer>) {
            
            _player = player
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(player: $player)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        playerController.delegate = context.coordinator
        playerController.showsPlaybackControls = false
        playerController.player?.play()
        return playerController
    }
    
    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {}
}

