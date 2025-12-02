/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing state data the speech-bubble system uses.
*/

import RealityKit

struct SpeechBubbleComponent: Component {
    var targetEntity: Entity
    var text: String = ""
    var isDown: Bool = true
    var isEnabled: Bool = false
    var offset: SIMD3<Float> = [0, 0.06, 0]
    var timer: Float = 0
    var scale: Float = 1
}
