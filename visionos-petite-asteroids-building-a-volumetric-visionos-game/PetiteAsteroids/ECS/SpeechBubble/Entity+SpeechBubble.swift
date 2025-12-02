/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for activating speech bubbles over entities with speech-bubble components.
*/

import RealityKit

extension Entity {
    func activateSpeechBubble(text: String, duration: Float, isDown: Bool = true, scale: Float = 1.0) {
        guard let speechBubble = self.scene?.first(withComponent: SpeechBubbleComponent.self)?.entity else {
            return
        }
        speechBubble.components[SpeechBubbleComponent.self]?.targetEntity = self
        speechBubble.components[SpeechBubbleComponent.self]?.text = text
        speechBubble.components[SpeechBubbleComponent.self]?.timer = duration
        speechBubble.components[SpeechBubbleComponent.self]?.isDown = isDown
        speechBubble.components[SpeechBubbleComponent.self]?.isEnabled = true
        speechBubble.components[SpeechBubbleComponent.self]?.scale = scale

    }
}
