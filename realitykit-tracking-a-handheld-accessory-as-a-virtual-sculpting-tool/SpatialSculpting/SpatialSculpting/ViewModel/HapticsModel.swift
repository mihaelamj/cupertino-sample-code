/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model of the haptics of the scene.
*/

import SwiftUI
import RealityKit
import GameController
import CoreHaptics

// A ViewModel for the haptics of interacting with sculpting.
@MainActor @Observable
final class HapticsModel {
    
    var hapticEngine: CHHapticEngine? = nil // The haptics engine to run haptics from.
    var hapticPattern: CHHapticPattern? = nil // This is a basic haptic pattern to play when sculpting into clay.
    var hapticPlayer: CHHapticPatternPlayer? = nil // This can play haptic patterns.

}
