/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that describes video content.
*/

import RealityKit
import SwiftUI

struct VideoModel: Hashable, Identifiable {
    enum ContentType: Hashable {
        enum Mode: Hashable {
            case mono
            case stereo
        }

        case aiv
        case apmp(Mode)
        case spatial
    }

    let id: UUID
    let contentType: VideoModel.ContentType
    let url: URL
    let background: Color
    let imageName: String?
    let title: String
    let subtitle: String
    
    init(
        identifier: UUID = UUID(),
        contentType: ContentType,
        url: URL,
        background: Color = .secondary,
        imageName: String? = nil,
        title: String,
        subtitle: String? = nil
    ) {
        self.id = identifier
        self.contentType = contentType
        self.url = url
        self.background = background
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle ?? ""
    }

    var preferredPlaybackScene: AppModel.PlaybackScene {
        contentType.preferredPlaybackScene
    }
}

extension VideoModel.ContentType {
    var immersiveSceneID: String {
        switch self {
        case .aiv:
            ProgressivePlayerImmersiveSpace.sceneID
        case .apmp:
            ProgressivePlayerImmersiveSpace.sceneID
        case .spatial:
            SpatialPlayerImmersiveSpace.sceneID
        }
    }

    var immersiveTransitionSystemImageName: String {
        switch self {
        case .aiv, .apmp:
            "rectangle.arrowtriangle.2.outward"
        case .spatial:
            "pano.fill"
        }
    }

    var portalTransitionSystemImageName: String {
        switch self {
        case .aiv, .apmp:
            "rectangle.arrowtriangle.2.inward"
        case .spatial:
            "pano"
        }
    }

    fileprivate var preferredPlaybackScene: AppModel.PlaybackScene {
        switch self {
        case .aiv:
            .immersive(sceneID: ProgressivePlayerImmersiveSpace.sceneID)
        case .apmp:
            .immersive(sceneID: ProgressivePlayerImmersiveSpace.sceneID)
        case .spatial:
            .window
        }
    }
}

extension VideoModel.ContentType.Mode {
    var desiredViewingMode: VideoPlaybackController.ViewingMode {
        switch self {
        case .mono:
            .mono
        case .stereo:
            .stereo
        }
    }
}
