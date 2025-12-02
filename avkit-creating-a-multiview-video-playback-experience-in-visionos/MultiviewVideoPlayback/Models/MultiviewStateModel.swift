/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model for the shared state of the multiview experience.
*/

import AVKit
import SwiftUI

@Observable @MainActor
final class MultiviewStateModel: AVExperienceController.Delegate {
    /// The videos to display in the multiview experience.
    var videoModels: [VideoModel] = []

    /// References the item to display in the embedded state.
    var embeddedVideo: VideoModel?

    /// Whether the application supports the embedded playback experience.
    let supportsEmbeddedPlaybackExperience = false

    /// The count of videos in the multiview experience. Use this to determine whether to pause the video or to set it
    /// as the embedded video when leaving the multiview experience.
    var videosInMultiview: Int {
        videoModels.count { $0.isAddedToMultiview }
    }

    /// The scene to use as the fallback placement for instances where you don't use the embedded experience.
    var scene: UIScene?

    var loadingVideos = true

    func populate(with videos: [Video]) {
        let videoModels = videos.map {
            VideoModel(video: $0)
        }
        self.embeddedVideo = nil
        self.videoModels = videoModels

        self.videoModels.forEach { videoModel in
            videoModel.viewController.experienceController.delegate = self
        }

        loadingVideos = false
    }

    func videoSelected(videoModel: VideoModel, inMultiview: Bool) async {
        if inMultiview {
            // Deselecting a video from the content selection view transitions it
            // to the embedded experience even when there's one video playing.
            // Deselecting the last video removes the user from the multiview
            // experience, and returns them to the embedded playback experience.
            await videoModel.viewController.experienceController.transition(
                to: videoModel.isAddedToMultiview ? .embedded : .multiview
            )
        } else {
            if supportsEmbeddedPlaybackExperience {
                // Pause the current embedded video, if there is one.
                await embeddedVideo?.pauseVideoAndResetPlaybackCursor()

                // If the selected video isn't in the view hierarchy,
                // add and play it; otherwise, pause and remove it.
                if videoModel.viewController.parent == nil {
                    embeddedVideo = videoModel
                    await videoModel.resetPlaybackCursorAndPlayVideo()
                } else {
                    embeddedVideo = nil
                    await videoModel.pauseVideoAndResetPlaybackCursor()
                }
            } else {
                if case .completed = await videoModel.viewController.experienceController.transition(to: .expanded) {
                    await videoModel.resetPlaybackCursorAndPlayVideo()
                }
            }
        }
    }

    func experienceController(
        _ controller: AVExperienceController,
        didChangeTransitionContext context: AVExperienceController.TransitionContext
    ) {
        guard let videoModel = videoModel(for: controller) else {
            assertionFailure("Failed to get item for experience controller")
            return
        }

        if case .transitioning = context.status, videosInMultiview == 0 {
            // If there aren't any videos in the multiview experience,
            // update the selection state so that while the transition
            // is occurring, the UI reflects the added video.
            videoModel.isAddedToMultiview = context.toExperience != .embedded
        }

        guard
            case .finished(let result) = context.status,
            .completed == result
        else { return }

        videoModel.isAddedToMultiview = context.toExperience == .multiview

        // Play new videos that someone successfully adds to the multiview experience.
        if videoModel.isAddedToMultiview, videosInMultiview > 1 {
            Task { await videoModel.resetPlaybackCursorAndPlayVideo() }
        }

        // If the initial playback experience isn't embedded, remove the embedded video
        // from the view hierarchy when transitioning back to the embedded experience.
        if !supportsEmbeddedPlaybackExperience, context.toExperience == .embedded {
            embeddedVideo = nil
            Task { await videoModel.pauseVideoAndResetPlaybackCursor() }
        }
    }

    func experienceController(
        _ controller: AVExperienceController,
        prepareForTransitionUsing context: AVExperienceController.TransitionContext
    ) async {
        guard let videoModel = videoModel(for: controller) else {
            assertionFailure("Failed to get item for experience controller")
            return
        }

        if context.toExperience == .embedded, videosInMultiview == 1 {
            embeddedVideo = videoModel
        }

        if
            let player = videoModel.viewController.player,
            player.currentTime() == player.currentItem?.duration
        {
            await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player.play()
        }

        setFallbackScene(for: controller, using: context)
    }

    func setFallbackScene(for controller: AVExperienceController, using context: AVExperienceController.TransitionContext) {
        // The fallback placement is required for cases where the video doesn't start from the embedded state,
        // or the video needs to present on top of another scene.
        // If the video starts in the embedded state, you don't need to set the fallback placement.
        if !supportsEmbeddedPlaybackExperience, context.toExperience == .expanded {
            if let scene {
                controller.configuration.expanded.fallbackPlacement = .over(scene: scene)
            } else {
                controller.configuration.expanded.fallbackPlacement = .unspecified
            }
        }
    }

    func experienceController(
        _ controller: AVExperienceController,
        didChangeAvailableExperiences availableExperiences: AVExperienceController.Experiences
    ) {
        // No op
    }

    func videoModel(for experienceController: AVExperienceController) -> VideoModel? {
        videoModels.first { item in
            item.viewController.experienceController === experienceController
        }
    }
}
