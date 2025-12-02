/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the state for the fader system.
*/

import RealityKit

struct GameInfoComponent: Component {
    
    /// Use this to distinguish between the tutorial level and the main level.
    public var currentLevel: GameLevel?
    
    /// Returns `true` if the current level is a tutorial.
    var isTutorial: Bool {
        if let currentLevel = self.currentLevel {
            return currentLevel == .intro
        } else {
            return false
        }
    }
}
