/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing references to the bottom and top ambience audio playback controllers.
*/

import RealityKit

/// A component that stores a reference to the bottom and top audio playback controllers for ambient audio.
struct ButteAmbienceBlendComponent: Component {

    var bottom: AudioPlaybackController?
    var top: AudioPlaybackController?

    /// Blends between the bottom and top audio playback controllers by setting their gain using a percent value from zero (bottom) to one (top).
    @MainActor
    var blend: Float = .zero {
        didSet {
            bottom?.gain = Audio.Decibel(decibels(amplitude: 1 - blend))
            top?.gain = Audio.Decibel(decibels(amplitude: blend))
        }
    }
}

func decibels(amplitude: Float) -> Float { 20 * log10(amplitude) }
