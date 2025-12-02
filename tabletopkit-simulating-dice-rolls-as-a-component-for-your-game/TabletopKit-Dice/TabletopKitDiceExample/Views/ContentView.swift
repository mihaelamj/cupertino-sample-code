/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main UI that presents a dice rolling game view with immersive dice simulation.
*/
import SwiftUI
import RealityKit
import TabletopKit

struct ContentView: View {
    @Environment(Game.self) var game
    @State var predeterminedOutcome: Bool = false
    @State var tossAllDice: Bool = false
    
    var body: some View {
        GeometryReader3D { proxy3D in
            RealityView { (content: inout RealityViewContent) in
                content.entities.append(game.root)
                game.repositionTable(content: content, proxy: proxy3D)
            } update: { content in
                game.repositionTable(content: content, proxy: proxy3D)
            }
        }
        .tabletopGame(game.tabletopGame, parent: game.root) { initialInteractionValue in
            DiceInteraction(game: game,
                            predeterminedOutcome: predeterminedOutcome,
                            tossAllDice: tossAllDice,
                            initialInteractionValue: initialInteractionValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                HStack {
                    Text("Last roll score: \(game.lastRollScore)")
                    Toggle("Max score toss", isOn: $predeterminedOutcome)
                    Toggle("Toss all", isOn: $tossAllDice)
                }
            }
        }
    }
}
