/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension methods for the audio playback controller.
*/

import RealityKit

extension AudioPlaybackController {
    /// Sets the gain on an audio playback controller using a percent value from zero to one.
    public func setVolumePercent(_ percent: Float) {
        self.gain = Audio.Decibel(20 * log10(percent))
    }
}
