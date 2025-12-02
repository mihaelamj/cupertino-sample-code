/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class responsible for containing all the properties needed to display the video.
*/

import AVKit

@Observable
class VideoModel {
    let video: Video
    private let player: AVPlayer
    let viewController: AVPlayerViewController
    var isAddedToMultiview = false

    @MainActor
    init(video: Video) {
        let playerController = AVPlayerViewController()
        // Enable the multiview experience, along with the default recommended set.
        playerController.experienceController.allowedExperiences = .recommended(
            including: [.multiview]
        )

        self.video = video
        self.viewController = playerController
        self.player = .init(playerItem: video.playerItem)
        self.viewController.player = player
    }

    @MainActor
    func pauseVideoAndResetPlaybackCursor() async {
        player.pause()
        await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    @MainActor
    func resetPlaybackCursorAndPlayVideo() async {
        await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
    }
}
