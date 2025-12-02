/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that contains configurations that `AudioEffectSystem` uses to play a sound effect.
*/

import RealityKit

struct AudioEventComponent: Component {

    /// The name of the audio resource to play.
    let resourceName: String

    /// A percent value from zero to one that the app uses to set the volume of an audio playback controller.
    var volumePercent: Float = 1

    /// A value that modifies the speed of audio playback controller to adjust perceived pitch. Suggested values are between `0.25` and `4`.
    var speed: Float = 1
}
