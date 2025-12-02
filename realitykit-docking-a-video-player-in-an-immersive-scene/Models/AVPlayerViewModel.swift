/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model associated with the video player.
*/

import AVKit

@MainActor
@Observable
class AVPlayerViewModel: NSObject {
    var isPlaying: Bool = false
    private var avPlayerViewController: AVPlayerViewController?
    private var avPlayer = AVPlayer()
    private let videoURL: URL? = {
        return URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8")!
    }()

    func makePlayerViewController() -> AVPlayerViewController {
        let avPlayerViewController = AVPlayerViewController()
        avPlayerViewController.player = avPlayer
        avPlayerViewController.delegate = self
        self.avPlayerViewController = avPlayerViewController
        return avPlayerViewController
    }

    func play() {
        guard !isPlaying, let videoURL else { return }
        isPlaying = true

        let item = AVPlayerItem(url: videoURL)
        avPlayer.replaceCurrentItem(with: item)
        avPlayer.play()
    }

    func reset() {
        guard isPlaying else { return }
        isPlaying = false
        avPlayer.replaceCurrentItem(with: nil)
        avPlayerViewController?.delegate = nil
    }
}

extension AVPlayerViewModel: AVPlayerViewControllerDelegate {
    nonisolated func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        Task { @MainActor in
            reset()
        }
    }
}
