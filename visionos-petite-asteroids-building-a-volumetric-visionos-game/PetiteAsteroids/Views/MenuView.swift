/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that toggles between different subviews for the app.
*/

import SwiftUI
import RealityKit

enum MenuVisibility {
    case splashScreen
    case highScore
    case hidden
}

struct MenuView: View {
    
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            let gamePlayState = appModel.root.observable.components[GamePlayStateComponent.self]
            switch (gamePlayState, appModel.menuVisibility) {
                case (.loadingAssets, _):
                    LoadingView()
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                case (_, .splashScreen):
                    SplashScreenView()
                        .frame(maxHeight: 450)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                case (_, .highScore):
                    HighScoreView()
                        .frame(maxHeight: 600)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                default:
                    EmptyView()
            }
        }
        .frame(maxWidth: 800)
        .onChange(of: appModel.menuVisibility) {
            switch appModel.menuVisibility {
                case .highScore, .splashScreen:
                    if case .playing = appModel.root.components[GamePlayStateComponent.self] {
                        appModel.root.components.set(GamePlayStateComponent.playing(isPaused: true))
                    }
                case .hidden:
                    if case .playing = appModel.root.components[GamePlayStateComponent.self] {
                        appModel.root.components.set(GamePlayStateComponent.playing(isPaused: false))
                    }
            }
        }
    }
}

#Preview {
    MenuView()
}
