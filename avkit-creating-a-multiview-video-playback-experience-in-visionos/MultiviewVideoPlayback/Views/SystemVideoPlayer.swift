/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The preferred system video player in visionOS.
*/

import AVKit
import SwiftUI

struct SystemVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerController = AVPlayerViewController()
        playerController.player = player

        return playerController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
