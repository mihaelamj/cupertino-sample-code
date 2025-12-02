/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Set up haptics for the scene.
*/

import CoreHaptics
import GameController

extension HapticsModel {
    // Set up haptics engine and patterns for playing haptics.
    @MainActor
    func setupHaptics(haptics: GCDeviceHaptics) {
        if hapticEngine == nil {
            hapticEngine = haptics.createEngine(withLocality: .default)
            try? hapticEngine?.start()
        }
        
        if hapticPattern == nil {
            hapticPattern = try? CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ], relativeTime: 0.0, duration: 100.0)
            ], parameterCurves: [])
        }
        
        if let hapticPattern = hapticPattern {
            hapticPlayer = try? hapticEngine?.makePlayer(with: hapticPattern)
        }
    }
    
    // Start or stop haptics when sculpting.
    @MainActor
    func handleSculptHaptics(pressed: Bool) {
        if pressed {
            try? hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } else {
            try? hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
        }
    }
}
