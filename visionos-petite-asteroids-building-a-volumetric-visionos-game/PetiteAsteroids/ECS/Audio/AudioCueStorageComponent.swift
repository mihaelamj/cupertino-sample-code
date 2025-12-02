/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the state for the audio cue system.
*/

import RealityKit

/// A component that `AudioCueSystem`uses to store the state about active audio playback controllers.
struct AudioCueStorageComponent: Component {
    var controllers: [AudioCue: AudioPlaybackController] = [:]
}
