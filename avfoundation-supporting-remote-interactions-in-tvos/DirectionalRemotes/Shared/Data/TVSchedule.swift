/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a TV schedule.
*/

import Foundation
import AVKit

/// A representation of a TV schedule.
///
/// A TV schedule contains multiple channels, and each channel contains a list of programs.
class TVSchedule {
    /// The shared instance of the TV schedule.
    static let shared: TVSchedule = TVSchedule()

    private init() {}

    /// The list of available channels.
    lazy var channels: [Channel] = {
        defaultAssets
    }()

    /// The list of `AVPlayerItem` objects representing the current program of each `Channel`.
    var playerItems: [AVPlayerItem] {
        channels.compactMap { AVPlayerItem(withChannel: $0) }
    }

}

extension TVSchedule {
    /// The default list of `Channel` values to set up the TV schedule.
    private var defaultAssets: [Channel] {
        return [
            Channel(name: "APPL", programs: [
                Program(title: "Platforms State of the Union 2019", description: "WWDC 2019 Platforms State of the Union", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2019/103bax22h2udxu0n/103/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "APPL+", programs: [
                Program(title: "Platforms State of the Union 2021", description: "Take a deeper dive into the new tools, technologies, and advances across Apple platforms that will help you create even better apps.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2021/102/9/185FF8CB-65B8-468D-9AF3-E6B6444F9AB7/cmaf.m3u8")
            ]),

            Channel(name: "ATV", programs: [
                Program(title: "WWDC 2018 Keynote", description: "WWDC 2018 Keynote", playlistURLString: "https://p-events-delivery.akamaized.net/18oijbasfvuhbfsdvoijhbsdfvljkb6/m3u8/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "ATV+", programs: [
                Program(title: "Mastering the Living Room With tvOS", description: "tvOS apps can deliver amazing experiences with stunning picture quality through 4K resolution, Dolby Vision and HDR10, and immersive sound through Dolby Atmos. Discover how to design beautiful, engaging, content-first experiences for your media applications. Learn about the new Top Shelf extension and styles to engage customers in your content before they even open your app. Take advantage of user profile support to offer an even more intuitive shared device experience.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2019/211p61zvgdkn99y/211/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "KC", programs: [
                Program(title: "Platforms State of the Union 2018", description: "2018 Platforms State of the Union", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "KC+", programs: [
                Program(title: "What's New in tvOS 12", description: "Apps on tvOS entertain, inform, and inspire with their content and interactive experiences. tvOS 12 brings new technologies that help make these experiences even more enjoyable and engaging. Get an introduction to focus engine support for non-UIKit apps, new UI elements, and Password AutoFill. Learn how to bring it all together to create incredible tvOS apps and experiences.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/208piymryv9im6/208/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "MacTV", programs: [
                Program(title: "What's new in Mac Catalyst", description: "Discover the latest updates to Mac Catalyst and find out how you can make your app feel even more at home on macOS. Learn about a variety of new and enhanced UIKit APIs that let you customize your Mac Catalyst app to take advantage of behaviors unique to macOS. To get the most out of this session, we recommend a basic familiarity with Mac Catalyst. Check out “Introducing iPad Apps for Mac” from WWDC19 to acquaint yourself. For more on refining your Mac Catalyst app, watch “Optimize the interface of your Mac Catalyst app” from WWDC20.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2021/10052/3/AEC7031C-E8E6-4F09-B845-F0DE96310C4D/cmaf.m3u8")
            ]),

            Channel(name: "MacTV+", programs: [
                Program(title: "Deploy macOS Big Sur in your organization", description: "Discover the latest on the platform changes in macOS Big Sur and Mac computers with the Apple M1 chip, including features available in macOS Big Sur 11.3. Learn about macOS Big Sur management capabilities and strategies for deploying in business and education. Hear about changes to deployment workflows for both one-to-one and shared deployments.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/tech-talks/10870/2/F78B8959-C69D-43DD-9AC1-DD5F66949287/cmaf.m3u8")
            ]),

            Channel(name: "UITV+", programs: [
                Program(title: "Apple Design Awards 2018", description: "Join us for an unforgettable award ceremony celebrating developers and their outstanding work. The 2018 Apple Design Awards recognize state of the art iOS, macOS, watchOS, and tvOS apps that reflect excellence in design and innovation.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/103zvtnsrnrijr/103/hls_vod_mvp.m3u8")
            ]),

            Channel(name: "WTV+", programs: [
                Program(title: "Meet Apple Watch Series 7", description: "Apple Watch Series 7 introduces new device sizes and a display that features a subtle wraparound effect. Learn how you can adapt your watchOS app design to look great on all screen sizes: We'll show you how to take advantage of a larger content area, create clearer hierarchy using color and typography, and improve glanceability in your app by creating better navigation.", playlistURLString: "https://devstreaming-cdn.apple.com/videos/tech-talks/10884/5/8CE65AF6-A55C-479D-B91B-7A94D31B38EC/cmaf.m3u8")
            ])
        ]
    }
}
