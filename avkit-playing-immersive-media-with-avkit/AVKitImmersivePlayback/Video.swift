/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a video in the app's library.
*/

import Foundation
import UIKit

struct Video: Identifiable {

    /// The unique identifier of the item.
    let id = UUID()
    /// The URL of the video, which can be local or remote.
    let url: URL
    /// The title of the video.
    let title: LocalizedStringResource
    /// The description of the video.
    let description: LocalizedStringResource
    /// The image name.
    let imageName: String
    /// The data for the image to create a metadata item to display in the player UI's Info panel.
    var imageData: Data {
        UIImage(named: imageName)?.pngData() ?? Data()
    }

    static let library: [Video] = [
        .init(
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/spatialLighthouseFlowersWaves/mvp.m3u8")!,
            title: "Spatial Flowers",
            description: "Watch flowers gently sway in the ocean breeze.",
            imageName: "spatial_thumbnail"
        ),
        .init(
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/wfovCausewayWalk/mvp.m3u8")!,
            title: "WFOV Causeway",
            description: "Enjoy a scenic walk down the causeway.",
            imageName: "wfov_thumbnail"
        ),
        .init(
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/180Lighthouse/mvp.m3u8")!,
            title: "180° Lighthouse",
            description: "Stand at the entrance of a lighthouse.",
            imageName: "180_thumbnail"
        ),
        .init(
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/360Lighthouse/mvp.m3u8")!,
            title: "360° Lighthouse",
            description: "Feel the ocean waves crash around you.",
            imageName: "360_thumbnail"
        ),
        .init(
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/apple-immersive-video/primary.m3u8")!,
            title: "Apple Immersive Video",
            description: "Fly over a beautiful beach at sunset.",
            imageName: "aiv_thumbnail"
        )
    ]
}

