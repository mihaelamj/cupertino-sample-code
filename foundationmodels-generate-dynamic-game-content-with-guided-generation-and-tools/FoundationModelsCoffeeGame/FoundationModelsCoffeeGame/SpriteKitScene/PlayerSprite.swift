/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SpriteKit node that represents the player and controls their movement.
*/

import SpriteKit

class PlayerSprite: SKSpriteNode {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // ensure no anti-aliasing for crisp pixel art
        texture?.filteringMode = .nearest
    }

    func movePlayer(_ location: CGPoint) {
        // move the player sprite towards the touch point
        let step = 5.0
        let xDist = CGFloat(min(abs(position.x - location.x), step))
        let yDist = CGFloat(min(abs(position.y - location.y), step))
        let xDir = position.x > location.x ? -1.0 : 1.0
        let yDir = position.y > location.y ? -1.0 : 1.0
        position.x += CGFloat(xDist * xDir)
        position.y += CGFloat(yDist * yDir)
        zPosition = position.y * -1.0
    }
}
