/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing state data for animating the character.
*/

import SwiftUI
import RealityKit

struct CharacterAnimationComponent: Component {
    /// Use the ID to reference the character entity, which is a sibling of the animation entity.
    public var characterEntityId: UInt64 = 0
    
    /// A timer tracking the duration of the character's current animation.
    public var animationTimer: Float = 0
    
    /// A timer tracking when `CharacterAnimationSystem` needs to show the character's eyes.
    public var eyeAppearTimer: Float = Float.greatestFiniteMagnitude
    
    /// Keep a reference to the viewpoint of `Volume`.
    var volumeViewpoint: Viewpoint3D = .standard
}
