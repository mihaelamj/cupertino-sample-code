/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SpriteKit node that represents a character.
*/

import SpriteKit

// The view model of character sprite image that appears in the CoffeeShopScene
class CharacterSprite: SKSpriteNode {
    // callback to the SwiftUI code that will display the actual dialog on screen
    internal var showDialog: ((any Character) -> Void)?
    
    // callback to check if the player is close enough to interact with this character
    internal var checkProximity: ((CGPoint) -> Bool)?
    
    // connects a character profile to this view model
    private var character: (any Character)?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        character = createCharacter()
        isUserInteractionEnabled = true
        // ensure no anti-aliasing for crisp pixel art
        texture?.filteringMode = .nearest
    }
    
    init(texture: SKTexture?, size: CGSize) {
        super.init(texture: texture, color: .clear, size: size)
        character = createCharacter()
        isUserInteractionEnabled = true
    }

    func createCharacter() -> any Character {
        // Barista is the default character
        return Barista()
    }

    /* This allows the character sprite image to respond to player interaction.
     For iOS, the player taps the character's image. For macOS, the player clicks
     the character image. */
    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        startDialog()
    }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) {
        startDialog()
    }
    #endif

    func startDialog() {
        if let showDialog, let character, let checkProximity {
            if checkProximity(position) {
                showDialog(character)
            }
        }
    }
}

class BaristaSprite: CharacterSprite {
    override func createCharacter() -> any Character {
        Barista()
    }
}

class CustomerLisaSprite: CharacterSprite {
    override func createCharacter() -> any Character {
        CustomerLisa()
    }
}

class GeneratedCustomerSprite: CharacterSprite {
    let character: any Character
    init?(character: any Character) {
        self.character = character
        super.init(
            texture: SKTexture(imageNamed: "Customer2"),
            size: CGSize(width: 76.5, height: 180)
        )
        // ensure no anti-aliasing for crisp pixel art
        texture?.filteringMode = .nearest
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func createCharacter() -> any Character {
        character
    }
}
