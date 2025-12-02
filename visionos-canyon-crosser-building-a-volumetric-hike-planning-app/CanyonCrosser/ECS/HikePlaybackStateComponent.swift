/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component to set the state of the playback.
*/

import RealityKit

struct HikePlaybackStateComponent: Component {
    /// When pausing the hike, the slider icon shows the standing figure.
    /// The playback button on the left of the slider switches between a play button and pause button.
    var isPaused: Bool = true
}
