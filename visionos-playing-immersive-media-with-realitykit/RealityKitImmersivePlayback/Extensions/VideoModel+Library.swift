/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of VideoModel that describes the library of content available for playback.
*/

import Foundation
import SwiftUI

extension VideoModel {
    static let library: [VideoModel] = [
        VideoModel(
            contentType: .spatial,
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/spatialLighthouseFlowersWaves/mvp.m3u8")!,
            imageName: "spatial",
            title: "Lighthouse Flowers",
            subtitle: "Spatial Video"
        ),
        VideoModel(
            contentType: .apmp(.stereo),
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/180Lighthouse/mvp.m3u8")!,
            imageName: "apmp_180",
            title: "Lighthouse",
            subtitle: "APMP 180"
        ),
        VideoModel(
            contentType: .apmp(.mono),
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/360Lighthouse/mvp.m3u8")!,
            imageName: "apmp_360",
            title: "Breaking Waves",
            subtitle: "APMP 360"
        ),
        VideoModel(
            contentType: .apmp(.mono),
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/wfovCausewayWalk/mvp.m3u8")!,
            imageName: "apmp_wfov",
            title: "Causeway",
            subtitle: "APMP WFoV"
        ),
        VideoModel(
            contentType: .aiv,
            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/immersive-media/apple-immersive-video/primary.m3u8")!,
            imageName: "aiv",
            title: "Sunset Pier",
            subtitle: "Apple Immersive Video"
        )
    ]
}
