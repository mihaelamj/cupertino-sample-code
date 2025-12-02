/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model for the app.
*/

import AVFoundation
import RealityKit
import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
final class AppModel {
    let player: AVPlayer
    let playerModel: PlayerModel

    var immersiveSpaceState = ImmersiveSpaceState.default
    var windowState: WindowState? = .default
    var stage = Stage.default
    private(set) var pendingStage: Stage?
    private(set) var selectedVideo: VideoModel?
    private(set) var videoModes: VideoModes?

    init() {
        self.player = AVPlayer()
        self.playerModel = PlayerModel(player: player)
    }

    var needsHeadRelativePositioning: Bool {
        let prevailingScene = pendingStage?.playbackScene ?? playbackScene
        guard let scene = prevailingScene, let contentType = selectedContentType else {
            return false
        }

        switch scene {
        case .immersive:
            switch contentType {
            case .aiv, .apmp:
                return false
            case .spatial:
                return true
            }
        case .window:
            return false
        }
    }

    var playbackScene: PlaybackScene? {
        stage.playbackScene
    }

    var selectedContentType: VideoModel.ContentType? {
        selectedVideo?.contentType
    }

    var toggleSystemImageName: String? {
        guard let scene = playbackScene, let contentType = selectedContentType else {
            return nil
        }

        switch scene {
        case .immersive:
            return contentType.portalTransitionSystemImageName
        case .window:
            return contentType.immersiveTransitionSystemImageName
        }
    }

    func commitStage(_ newStage: AppModel.Stage) {
        stage = newStage
        pendingStage = nil
    }

    func requestStage(_ requestedStage: AppModel.Stage) {
        if stage != requestedStage {
            pendingStage = requestedStage
        }
    }

    func reset() {
        selectedVideo = nil
        videoModes = nil
    }
    
    func selectVideo(_ selection: VideoModel) {
        selectedVideo = selection
        videoModes = VideoModes(playbackScene: selection.preferredPlaybackScene, contentType: selection.contentType)
        playerModel.loadItem(selection)
        requestStage(.playing(selection.preferredPlaybackScene))
    }

    func toggleImmersion() {
        guard let playbackScene, let contentType = selectedContentType else {
            return
        }

        let nextScene = playbackScene.toggle(contentType: contentType)
        videoModes = VideoModes(playbackScene: nextScene, contentType: contentType)
    }
}

extension AppModel {
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
        
        static let `default` = ImmersiveSpaceState.closed
    }

    enum WindowState {
        case library
        case portalDefault
        case portalToggled

        static let `default` = WindowState.library
    }

    enum PlaybackScene: Equatable {
        case window
        case immersive(sceneID: String)

        static let `default` = PlaybackScene.window

        init?(immersiveViewingMode: VideoPlayerComponent.ImmersiveViewingMode) {
            switch immersiveViewingMode {
            case .full:
                self = .immersive(sceneID: SpatialPlayerImmersiveSpace.sceneID)
            case .progressive:
                self = .immersive(sceneID: ProgressivePlayerImmersiveSpace.sceneID)
            case .portal:
                self = .window
            @unknown default:
                debugPrint("Unrecognized case: \(immersiveViewingMode) — please update the switch to handle it.")
                return nil
            }
        }

        fileprivate func toggle(contentType: VideoModel.ContentType) -> PlaybackScene {
            switch self {
            case .immersive:
                .window
            case .window:
                .immersive(sceneID: contentType.immersiveSceneID)
            }
        }
    }
    
    enum Stage: Equatable {
        case browsing
        case playing(PlaybackScene)
        
        static let `default` = Stage.browsing

        fileprivate var playbackScene: PlaybackScene? {
            switch self {
            case .browsing:
                nil
            case .playing(let scene):
                scene
            }
        }
    }
}
