/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a stack of cans.
*/

import RealityKit

private let verticalSpacing: Float = 0.18
private let horizontalSpacing: Float = 0.18

@MainActor
final class CanStack: Entity {
    private(set) var cans: [Can] = []
    
    // A triangular stack of 10 cans.
    static private let canPositions: [SIMD3<Float>] = [[-(horizontalSpacing * 1.5), (verticalSpacing * 0), 0], // 1st floor
                                                       [-(horizontalSpacing * 0.5), (verticalSpacing * 0), 0], // 1st floor
                                                       [(horizontalSpacing * 0.5), (verticalSpacing * 0), 0],  // 1st floor
                                                       [(horizontalSpacing * 1.5), (verticalSpacing * 0), 0],  // 1st floor
                                                       [(horizontalSpacing * 0), (verticalSpacing * 1), 0],    // 2nd floor
                                                       [(horizontalSpacing * 1), (verticalSpacing * 1), 0],    // 2nd floor
                                                       [-(horizontalSpacing * 1), (verticalSpacing * 1), 0],   // 2nd floor
                                                       [(horizontalSpacing * 0.5), (verticalSpacing * 2), 0],  // 3rd floor
                                                       [-(horizontalSpacing * 0.5), (verticalSpacing * 2), 0], // 3rd floor
                                                       [horizontalSpacing * 0, (verticalSpacing * 3), 0]]      // 4th floor
    required init() {
        super.init()

        for canPosition in CanStack.canPositions {
            let newCan = Can(position: canPosition)
            addChild(newCan)
            cans.append(newCan)
        }
        
        // Place the stack on the pedestal.
        position = [0, 0, 0.25]
    }
}
