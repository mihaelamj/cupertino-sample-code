/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup of the scene and views for the app.
*/
import Foundation
import RealityKit
import SwiftUI
import TabletopKit
import GroupActivities

// MARK: App entry point

@MainActor
@main
struct MiniGameApp: App {
    @State var game: Game
    
    init() {
        self.game = Game()
    }
    var body: some SwiftUI.Scene {
        WindowGroup {
            GameView()
                .environment(game)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 2, depth: 2, in: .meters)
    }
}

@MainActor
struct GameView: View {
    @Environment(Game.self) var game
    @State private var activityManager: GroupActivityManager?
    let volumetricRoot: Entity

    init() {
        volumetricRoot = Entity()
        volumetricRoot.name = "volumetricRoot"
    }

    var body: some View {
        GeometryReader3D { proxy3D in
            RealityView { (content: inout RealityViewContent, attachments) in
                for index in 0 ..< game.playerStats.count {
                    guard let playerStat = attachments.entity(for: index) else {
                        return
                    }
                    playerStat.components.set(BillboardComponent())
                    playerStat.position = [
                        Float(PlayerSeat.playerStatPositions[index].x),
                        -0.05,
                        Float(PlayerSeat.playerStatPositions[index].z)
                    ]
                    playerStat.isEnabled = true
                    volumetricRoot.addChild(playerStat)
                }
                
                content.entities.append(volumetricRoot)
                // Set the root at the base of the volume.
                let frame = content.convert(proxy3D.frame(in: .local), from: .local, to: volumetricRoot)
                volumetricRoot.transform.translation.y = frame.min.y
                volumetricRoot.addChild(game.renderer.root)
            }
            attachments: {
                ForEach(0..<game.playerStats.count, id: \.self) { index in
                    Attachment(id: index) {
                        HStack(spacing: 50) {
                            Text("❤️ \(game.playerStats[index].health)").font(.largeTitle)
                            Text("⭐️ \(game.playerStats[index].coinsCount)").font(.largeTitle)
                        }
                        .padding()
                    }
                }
            }
        }.toolbar() {
            GameToolbar(game: game)
        }.tabletopGame(game.tabletopGame, parent: game.renderer.root) { value in
            // Return the corresponding `TabletopInteraction.Delegate` for different equipment types.
            var delegate: GameInteraction?
            if game.tabletopGame.equipment(of: Log.self, matching: value.startingEquipmentID) != nil {
                delegate = LogInteraction(game: game)
            } else if game.tabletopGame.equipment(of: LilyPad.self, matching: value.startingEquipmentID) != nil {
                delegate = LilyPadInteraction(game: game)
            } else if game.tabletopGame.equipment(of: Player.self, matching: value.startingEquipmentID) != nil {
                delegate = PlayerInteraction(game: game)
            } else {
                delegate = GameInteraction(game: game)
            }

            return delegate!
        }.task {
            activityManager = GroupActivityManager(tabletopGame: game.tabletopGame)
        }
    }
}

struct GameToolbar: ToolbarContent {
    let game: Game
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomOrnament) {
            Button(action: {
                game.gameStarted ? game.resetGame() : game.startGame()
            }) {
                Text(game.gameStarted ? "Reset" : "Start Game")
            }.disabled(!game.isHost)
            Button("SharePlay", systemImage: "shareplay") {
               Task {
                    try! await Activity().activate()
               }
            }
        }
    }
}
