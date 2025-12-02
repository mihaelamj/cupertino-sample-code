/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SpriteKit node that represents a randomly generated customer, shown as a coffee cup.
*/

import Foundation
import SpriteKit

class RandomDreamSprite: SKSpriteNode {
    var dreamCustomer: NPC?
    var triggerEncounter: ((NPC) -> Void)?
    var checkProximity: ((CGPoint) -> Bool)?

    init?(npc: NPC) {
        super.init(
            texture: SKTexture(imageNamed: "glowSprite"),
            color: .clear,
            size: CGSize(width: 60, height: 42)
        )
        dreamCustomer = npc
        isUserInteractionEnabled = true

        // ensure no anti-aliasing for crisp pixel art
        texture?.filteringMode = .nearest

        // randomly position below the coffee bar in the scene
        position.x = CGFloat.random(in: -320..<320)
        position.y = CGFloat.random(in: -480..<160)
        self.zPosition = position.y * -1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animate() {
        let dist = Double.random(in: 10...30)
        let dur = Double.random(in: 1...2)
        run(
            .sequence([
                .wait(forDuration: Double.random(in: 0...1)),
                .repeatForever(
                    .sequence([
                        .moveBy(x: dist, y: 0.0, duration: dur),
                        .moveBy(x: 0.0, y: dist, duration: dur),
                        .moveBy(x: dist * -1.0, y: 0.0, duration: dur),
                        .moveBy(x: 0.0, y: dist * -1.0, duration: dur)
                    ])
                )
            ])
        )
    }

    /* This allows the customer sprite image to respond to player interaction.
     For iOS, the player taps the character's image. For macOS, the player clicks
     the character image. */
    #if os(iOS)
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let triggerEncounter, let checkProximity, let dreamCustomer {
                if checkProximity(position) {
                    triggerEncounter(dreamCustomer)
                }
            }
        }
    #elseif os(macOS)
        override func mouseDown(with event: NSEvent) {
            if let triggerEncounter, let dreamCustomer {
                triggerEncounter(dreamCustomer)
            }
        }
    #endif
}
