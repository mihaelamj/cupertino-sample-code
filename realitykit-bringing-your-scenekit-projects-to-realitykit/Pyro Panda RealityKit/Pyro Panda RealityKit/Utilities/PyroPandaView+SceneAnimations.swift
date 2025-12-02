/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup for the mobile platforms in the Pyro Panda game.
*/

import RealityKit
import Foundation

extension PyroPandaView {
    func animatePlatforms(_ platform1: Entity, _ platform2: Entity) {
        let platform1Start = platform1.position
        let platform2Start = platform2.position
        let oneToTwoX = platform2Start.x - platform1Start.x
        let platform1End = platform1Start + [oneToTwoX, 0, 0]
        let platform2End = platform2Start - [oneToTwoX, 0, 0]

        // Animate platform 1.
        let moveBetween1 = MoveBetweenComponent(
            startPosition: platform1Start,
            endPosition: platform1End,
            duration: 6
        )
        platform1.components.set(moveBetween1)

        // Animate platform 2.
        let moveBetween2 = MoveBetweenComponent(
            startPosition: platform2Start,
            endPosition: platform2End,
            duration: 6
        )
        platform2.components.set(moveBetween2)
    }

}
