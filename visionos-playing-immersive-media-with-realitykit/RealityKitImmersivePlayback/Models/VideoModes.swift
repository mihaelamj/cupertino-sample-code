/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An abstraction for configuration of modes within a VideoPlayerComponent.
*/

import RealityKit

struct VideoModes: Equatable {
    let immersiveViewingMode: VideoPlayerComponent.ImmersiveViewingMode?
    let spatialVideoMode: VideoPlayerComponent.SpatialVideoMode?
    let viewingMode: VideoPlaybackController.ViewingMode?

    init(
        immersiveViewingMode: VideoPlayerComponent.ImmersiveViewingMode? = nil,
        spatialVideoMode: VideoPlayerComponent.SpatialVideoMode? = nil,
        viewingMode: VideoPlaybackController.ViewingMode? = nil
    ) {
        self.immersiveViewingMode = immersiveViewingMode
        self.spatialVideoMode = spatialVideoMode
        self.viewingMode = viewingMode
    }
}

extension VideoModes {
    init(playbackScene: AppModel.PlaybackScene, contentType: VideoModel.ContentType) {
        var immersiveViewingMode: VideoPlayerComponent.ImmersiveViewingMode? = nil
        var spatialVideoMode: VideoPlayerComponent.SpatialVideoMode? = nil
        var viewingMode: VideoPlaybackController.ViewingMode? = nil

        switch playbackScene {
        case .immersive:
            switch contentType {
            case .aiv:
                immersiveViewingMode = .progressive
                viewingMode = .stereo
            case .apmp(let mode):
                immersiveViewingMode = .progressive
                viewingMode = mode.desiredViewingMode
            case .spatial:
                immersiveViewingMode = .full
                spatialVideoMode = .spatial
                viewingMode = .stereo
            }
        case .window:
            switch contentType {
            case .aiv:
                immersiveViewingMode = .portal
                viewingMode = .stereo
            case .apmp(let mode):
                immersiveViewingMode = .portal
                viewingMode = mode.desiredViewingMode
            case .spatial:
                immersiveViewingMode = .portal
                spatialVideoMode = .spatial
                viewingMode = .stereo
            }
        }

        self.init(
            immersiveViewingMode: immersiveViewingMode,
            spatialVideoMode: spatialVideoMode,
            viewingMode: viewingMode
        )
    }

    @MainActor
    init(appModel: AppModel) {
        guard let playbackScene = appModel.playbackScene, let videoModel = appModel.selectedVideo else {
            self = VideoModes()
            return
        }

        self.init(
            playbackScene: playbackScene,
            contentType: videoModel.contentType
        )
    }
}
