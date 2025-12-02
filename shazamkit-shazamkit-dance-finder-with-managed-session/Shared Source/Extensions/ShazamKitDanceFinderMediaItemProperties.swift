/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension for custom ShazamKit media item properties.
*/

import ShazamKit

extension SHMediaItemProperty {
    static let videoTitle = SHMediaItemProperty("videoTitle")
}

extension SHMediaItem {
    var videoTitle: String? {
        return self[.videoTitle] as? String
    }
}
