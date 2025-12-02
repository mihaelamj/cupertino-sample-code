/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that holds configuration data for the intro animation.
*/

import RealityKit

struct IntroAnimationConfigComponent: Component {
    var willPreserveCharacterWorldPosition = true
    var willShowSpeechBubble = true
    var willStartGameWhenComplete = true
}
