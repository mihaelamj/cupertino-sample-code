/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility methods for the rock-collector system.
*/

import RealityKit
import RealityKitContent

extension RockCollectorSystem {
    @MainActor
    func ballisticVelocity (from start: SIMD3<Float>,
                            to end: SIMD3<Float>,
                            gravity: Float,
                            time: inout Float,
                            testNegative: Bool = false) -> SIMD3<Float>? {
        let direction = end - start
        let horizontal = SIMD2<Float>(direction.x, direction.z)
        let distance = length(horizontal)
        let height = direction.y

        // Automatically use the negative solution for steep downward trajectories.
        let useNegativeSolution = testNegative || (height < 0 && abs(height) > distance)

        let root = sqrt(distance * distance + height * height)
        let denom = height + root * (useNegativeSolution ? -1 : 1)

        // Handle special cases for steep downward trajectories.
        if denom <= .ulpOfOne {
            // When destination is significantly below start, use a direct downward trajectory.
            if height < 0 {
                // Calculate the minimum time needed for free-fall under gravity.
                let freefallTime = sqrt(-2 * height / gravity)

                // Add a small buffer to ensure hitting the target.
                time = freefallTime * 1.1

                // Calculate horizontal velocity components needed to reach the target.
                let velocityX = distance > .ulpOfOne ? horizontal.x / time : 0
                let velocityZ = distance > .ulpOfOne ? horizontal.y / time : 0

                // The initial vertical velocity for a modified free-fall.
                let velocityY = height / time + 0.5 * gravity * time

                return SIMD3<Float>(velocityX, velocityY, velocityZ)
            }
            return nil
        }

        // The standard ballistic calculation when the denominator is valid.
        time = sqrt(2 * denom / gravity)

        // Decompose into the components.
        let velocityX = horizontal.x / time
        let velocityZ = horizontal.y / time
        let velocityY = (height / time) + 0.5 * gravity * time

        return SIMD3<Float>(velocityX, velocityY, velocityZ)
    }
    
    func modNegativeSafe(_ valueA: Int, _ valueB: Int) -> Int {
        if valueB == 0 {
            return 0
        }
        return (valueA % valueB + valueB) % valueB
    }
}
