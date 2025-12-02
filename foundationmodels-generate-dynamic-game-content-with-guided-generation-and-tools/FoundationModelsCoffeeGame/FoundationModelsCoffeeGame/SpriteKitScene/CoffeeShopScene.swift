import FoundationModels
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SpriteKit scene that sets up player movement, camera, and sprites the player can interact with.
*/
import SpriteKit

class CoffeeShopScene: SKScene {
    var touchLocation: CGPoint?  // where the player touches the screen
    var showDialog: ((any Character) -> Void)?  // callback to show dialog
    var player: PlayerSprite?  // view model for the player's sprite image on screen

    // generates random customer from the player's contacts
    let randomCustomerGenerator = RandomCustomerGenerator()
    var isGeneratingEncounter: Bool = false

    // important: must be called immediately after initialization!
    static public func finishSetup(
        _ scene: CoffeeShopScene,
        showDialog: @escaping (any Character) -> Void
    ) {
        scene.showDialog = showDialog
        for child in scene.children {
            if let sprite = child as? SKSpriteNode {
                // ensure no anti-aliasing for crisp pixel art
                sprite.texture?.filteringMode = .nearest

                if let player = child as? PlayerSprite {
                    // save reference to player sprite
                    scene.player = player
                }
                if let character = child as? CharacterSprite {
                    // add hook to start dialog
                    character.showDialog = showDialog
                    character.checkProximity = scene.checkProximity(_:)
                }
            } else if let cam = child as? SKCameraNode {
                // set the camera
                scene.camera = cam
            }
        }

        // generate customer from the player's contacts
        scene.generateEncounter()
    }

    // add new floating coffee cup dream customer to the scene
    static public func addDreamCustomer(
        scene: CoffeeShopScene,
        npc: NPC,
        triggerEncounter: @escaping (NPC) -> Void
    ) {
        let spawn = RandomDreamSprite(npc: npc)!
        spawn.checkProximity = scene.checkProximity(_:)
        spawn.triggerEncounter = triggerEncounter
        scene.addChild(spawn)
        spawn.animate()
    }

    override func update(_ currentTime: TimeInterval) {
        if let touchLocation, let player {
            player.movePlayer(touchLocation)

            // update the camera
            moveCamera(player.position)
        }
    }

    func generateEncounter() {
        if isGeneratingEncounter {
            return
        }
        isGeneratingEncounter = true

        Task {
            let character = try await randomCustomerGenerator.generate()
            let sprite = GeneratedCustomerSprite(character: character)!
            sprite.showDialog = self.showDialog
            sprite.checkProximity = checkProximity(_:)
            self.addChild(sprite)
            isGeneratingEncounter = false
        }
    }

    // checks if the player is close enough to the target to interact
    func checkProximity(_ targetLocation: CGPoint) -> Bool {
        if let player {
            let dist = hypot(
                abs(targetLocation.x - player.position.x),
                abs(targetLocation.y - player.position.y)
            )
            Logging.general.log("distance: \(dist)")
            return dist < 200.0
        }
        return false
    }

    // moves the game camera to follow the player
    func moveCamera(_ playerLocation: CGPoint) {
        let stride = 0.25
        self.camera?.position.x.interpolate(towards: playerLocation.x, amount: stride)
        self.camera?.position.y.interpolate(towards: playerLocation.y, amount: stride)
    }

    /* allows the player to move around the scene. For iOS, register where the player
     touches the screen. For macOS, register where the player clicks the screen. */
    #if os(iOS)
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchLocation = touches.first?.location(in: self)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchLocation = touches.first?.location(in: self)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            touchLocation = nil
        }
    #elseif os(macOS)
        override func mouseDown(with event: NSEvent) {
            touchLocation = event.location(in: self)
        }
    #endif

}
