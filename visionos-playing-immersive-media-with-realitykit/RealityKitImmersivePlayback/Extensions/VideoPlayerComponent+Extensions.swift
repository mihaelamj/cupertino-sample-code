/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on VideoPlayerComponent.
*/

import RealityKit

extension VideoPlayerComponent {
    var needsScaling: Bool {
        (immersiveViewingMode == .portal || desiredImmersiveViewingMode == .portal)
    }
}

extension VideoPlayerComponent.VideoComfortMitigation {
    public var displayMessage: String? {
        switch self {
        case .play:
            return "High motion detected — continuing playback."
        case .pause:
            return "Playback has been paused to preserve motion comfort."
        case .reduceImmersion:
            return "Immersion has been reduced to preserve motion comfort."
        @unknown default:
            debugPrint("Unrecognized case: \(self) — please update the switch to handle it.")
            return nil
        }
    }
}
