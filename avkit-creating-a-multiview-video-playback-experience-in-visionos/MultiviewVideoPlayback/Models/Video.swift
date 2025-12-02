/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The details for each video.
*/

import AVFoundation
import AVKit
import Foundation
import UIKit

struct Video: Identifiable, Hashable {
    var id: String { url.absoluteString }
    let url: URL
    let title: String
    let subtitle: String
    let description: String

    var playerItem: AVPlayerItem {
        let playerItem = AVPlayerItem(url: url)
        Task { @MainActor in
            playerItem.externalMetadata = [
                .metadataItem(key: .commonIdentifierTitle, value: title),
                .metadataItem(key: .iTunesMetadataTrackSubTitle, value: subtitle),
                .metadataItem(key: .commonIdentifierDescription, value: description)
            ]
        }

        return playerItem
    }
}

extension AVMetadataItem {
    fileprivate static func metadataItem(key identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        // Return an immutable copy of the item.
        
        return item.copy() as! AVMetadataItem
    }
}

let defaultVideos: [Video] = [
    .init(
        url: URL(string: "https://playgrounds-cdn.apple.com/assets/beach/index.m3u8")!,
        title: "A Beach",
        subtitle: "waves crashing on a scenic California beach",
        description: """
                From an award-winning producer and actor, ”A Beach” is a sweeping, drama depicting waves crashing on a scenic California beach. \
                Sit back and enjoy the sweet sounds of the ocean while relaxing on a soft, sandy beach.
                """
    ),

    .init(
        url: URL(string: "https://playgrounds-cdn.apple.com/assets/lake/index.m3u8")!,
        title: "By the Lake",
        subtitle: "turtles on a log at the lake",
        description: """
            The battle for the sunniest spot continues, as a group of turtles take their positions on the log. \
            Find out who the last survivor is, and who swims away cold.
            """
    ),

    .init(
        url: URL(string: "https://playgrounds-cdn.apple.com/assets/camping/index.m3u8")!,
        title: "Camping in the Woods",
        subtitle: "listen to wildlife",
        description: """
            Come along for a journey of epic proportion as the perfect camp site is discovered. \
            Listen to the magical wildlife and feel the gentle breeze of the wind as you watch the daisies dance in the field of flowers.
            """
    ),

    .init(
        url: URL(string: "https://playgrounds-cdn.apple.com/assets/park/index.m3u8")!,
        title: "Birds in the Park",
        subtitle: "birds fluttering near the California hillside",
        description: """
            On a dreamy spring day near the California hillside, some friendly little birds flutter about, \
            hopping from stalk to stalk munching on some tasty seeds. Listen to them chatter as they go about their busy afternoon.
            """
    )
]
