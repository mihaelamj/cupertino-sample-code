/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A scene that displays a glowing ball.
*/

import UIKit
import SpriteKit

class BallScene: SKScene {
    
    // MARK: - Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
    override init(size: CGSize) {
        super.init(size: size)
        self.backgroundColor = UIColor.clear
    }
    
    // MARK: - Public Methods
    
    func flyBall(points: [CGPoint]) {
        DispatchQueue.main.async {
            if self.children.isEmpty {
                if let fireParticle = SKEmitterNode(fileNamed: "FireBall2") {
                    fireParticle.position = points.first!
                    fireParticle.targetNode = self
                    self.addChild(fireParticle)
                }
            } else {
                self.children.last?.position = points.last!
            }
        }
    }
    
}
