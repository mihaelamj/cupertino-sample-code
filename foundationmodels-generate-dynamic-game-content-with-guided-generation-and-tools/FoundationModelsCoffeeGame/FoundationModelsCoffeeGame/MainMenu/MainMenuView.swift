/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main menu of the game
*/

import FoundationModels
import SwiftUI

struct MainMenuView: View {

    enum ViewState {
        case mainMenu
        case game
    }

    @State var state: ViewState = .mainMenu

    var body: some View {
        switch state {
        case .mainMenu:
            fullMenuUI
        case .game:
            GameView()
                .background(Color.backgroundBrown)
        }
    }

    private var fullMenuUI: some View {
        ZStack {
            CloudsBackgroundView()
            mainUI
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundBrown)
        .tint(Color.darkBrown)
    }

    private var mainUI: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Dream Coffee")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
            }

            switch SystemLanguageModel.default.availability {
            case .available:
                gameStartButton
            case .unavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled:
                    Text(
                        "To play this game, turn on Apple Intelligence in Settings."
                    )
                    .modifier(GameBoxStyle())
                case .modelNotReady:
                    Text(
                        "Cannot start the game until model is ready to use. Come back later!"
                    )
                    .modifier(GameBoxStyle())
                case .deviceNotEligible:
                    Text(
                        ":( Sorry, this game needs a device compatible with Apple Intelligence."
                    )
                    .modifier(GameBoxStyle())
                default:
                    Text(
                        ":( Sorry, cannot start game. The model is unavailable for unknown reasons."
                    )
                    .modifier(GameBoxStyle())
                }
            }
        }

    }

    private var gameStartButton: some View {
        Button(action: {
            state = .game
        }) {
            Image(systemName: "plus")
            Text("New Game")
        }
        .buttonStyle(.plain)
        .modifier(GameBoxStyle())
    }
}

#Preview {
    MainMenuView()
}
