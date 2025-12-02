/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The representation of a thumbnail, including the image, time, and score.
*/

import AVFoundation

/// The class representation of a thumbnail.
class Thumbnail: Identifiable {
    /// The image that captures from the video frame.
    let image: CGImage

    /// The frame that the thumbnail represents.
    let frame: Frame

    init(image: CGImage, frame: Frame) {
        self.image = image
        self.frame = frame
    }
}
