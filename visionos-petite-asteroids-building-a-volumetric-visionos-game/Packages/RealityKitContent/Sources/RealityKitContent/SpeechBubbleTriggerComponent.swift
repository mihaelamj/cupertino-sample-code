/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as being a speech-bubble trigger.
*/

import RealityKit

@MainActor
public struct SpeechBubbleTriggerComponent: Component, Codable {
    public var characterText: String = "Update the text..."
    public var timer: Float = 5.0
    public var once: Bool = true
    public var hasBeenTriggered: Bool = false
    public var isTutorialGoal: Bool = false

    public init() {
    }
}
