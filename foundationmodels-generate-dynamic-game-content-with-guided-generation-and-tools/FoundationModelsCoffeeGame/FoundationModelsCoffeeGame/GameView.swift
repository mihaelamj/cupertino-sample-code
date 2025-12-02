/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of the app that sets up SwiftUI game views and the SpriteKit game scene.
*/

import SpriteKit
import SwiftUI

struct GameView: View {
    @State var skScene: CoffeeShopScene?
    @State var showModal: Bool = false
    @State var dialogEngine = DialogEngine()
    @State var encounterEngine = EncounterEngine()

    var body: some View {
        ZStack {
            if let skScene {
                SpriteView(scene: skScene)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()

                DialogBoxView(dialogEngine: dialogEngine)
            }
            .sheet(isPresented: $showModal) {
                ZStack {
                    Color(.backgroundBrown)

                    EncounterView(encounterEngine: encounterEngine)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            // load coffee shop SpriteKit scene
            if let scene = CoffeeShopScene(fileNamed: "CoffeeShopScene") {
                CoffeeShopScene.finishSetup(
                    scene,
                    showDialog: showDialog(_:),
                )
                scene.scaleMode = .aspectFill
                skScene = scene

                for _ in 0..<4 {
                    generateDreamCustomer()
                }
            }
        }
    }

    func showDialog(_ character: any Character) {
        dialogEngine.talkTo(character)
    }

    func generateDreamCustomer() {
        Task {
            if let skScene {
                do {
                    let npc = try await encounterEngine.generateNPC()
                    CoffeeShopScene.addDreamCustomer(
                        scene: skScene,
                        npc: npc,
                        triggerEncounter: triggerEncounter(_:)
                    )
                } catch let error {
                    Logging.general.log("Generation error for dream customer: \(error)")
                }
            }
        }
    }

    func triggerEncounter(_ npc: NPC) {
        Logging.general.log("trigger encounter! \(npc.name)")
        encounterEngine.customer = npc
        showModal = true
    }
}

// A retro box view style used throughout the game.
struct GameBoxStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .fontDesign(.monospaced)
            .background(.brown.secondary)
            .border(Color.brown, width: 6)
    }
}

#Preview {
    GameView()
}
