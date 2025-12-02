/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the system video player UI.
*/

import AVKit
import SwiftUI

#if canImport(UIKit)
/// A SwiftUI wrapper over `AVPlayerViewController` for iOS and visionOS.
struct PlayerView: UIViewControllerRepresentable {

    let player: AVPlayer

	func makeUIViewController(context: Context) -> AVPlayerViewController {
		let controller = AVPlayerViewController()
		controller.player = player
		controller.showsPlaybackControls = true
		return controller
	}
	
	func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update the player reference after it gets re-created.
        uiViewController.player = player
	}
}
#else
/// A SwiftUI wrapper over `AVPlayerView` for macOS.
struct PlayerView: NSViewRepresentable {

    var player: AVPlayer?

    func makeNSView(context: Context) -> some AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .floating
        playerView.player = player
        return playerView
    }

    func updateNSView(_ playerView: NSViewType, context: Context) {
        // Update the player reference after it gets re-created.
        playerView.player = player
    }
}
#endif

