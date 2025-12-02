/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing the state for the character audio system.
*/

import Foundation
import RealityKit

struct CharacterAudioComponent: Component {
    
    /// The number of seconds since last playing the roll sound effect.
    public var secondsElapsedSinceLastRoll: TimeInterval = .zero
    
    /// A list containing active audio playback controllers that the character uses.
    public var controllers: [AudioPlaybackController] = []
}
