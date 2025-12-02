/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that contains the state data the squash animation system uses.
*/

import RealityKit

struct SquashAnimationComponent: Component {
    
    var timer: Float = 0
    let multiplier: Float
    
    @MainActor
    public init (multiplier: Float) {
        self.multiplier = multiplier
        self.timer = GameSettings.maxSquashDuration * multiplier
    }
}
