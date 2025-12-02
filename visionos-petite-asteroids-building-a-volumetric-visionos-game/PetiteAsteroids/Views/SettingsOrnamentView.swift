/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A settings view to display in a volume ornament.
*/

import SwiftUI
import RealityKit

struct SettingsOrnamentView: View {
    @Environment(AppModel.self) private var appModel

    /// If the game level is main, show both buttons.
    private var menuIsExpanded: Bool {
        appModel.root.observable.components[GameInfoComponent.self]?.currentLevel == .main
    }

    var body: some View {
        @Bindable var appModel = appModel
        HStack {
            let gamePlayState = appModel.root.observable.components[GamePlayStateComponent.self]
            if menuIsExpanded {
                Button {
                    appModel.root.scene?.postRealityKitNotification(notification: GameSettings.respawnNotification)
                } label: {
                    Image(systemName: "arrow.uturn.left")
                }
                .disabled(gamePlayState?.isPlayingGame == false)
                .buttonStyle(.borderless)
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                .help("Jump to Continue Point")
                .padding(.leading)
            }

            Divider()
                .padding(.vertical, 5)

            Menu {
                VStack {
                    Picker("Roll : \(appModel.rollInputMode.rawValue)", selection: $appModel.rollInputMode) {
                        ForEach(RollInputMode.allCases, id: \.self) { inputMode in
                            HStack {
                                Text(inputMode.rawValue)
                                Image(systemName: inputMode.systemImageName)
                            }
                        }
                    }.pickerStyle(.menu)
                    Picker("Jump : \(appModel.jumpInputMode.rawValue)", selection: $appModel.jumpInputMode) {
                        ForEach(JumpInputMode.allCases, id: \.self) { inputMode in
                            HStack {
                                Text(inputMode.rawValue)
                                Image(systemName: inputMode.systemImageName)
                            }
                        }
                    }.pickerStyle(.menu)
                    
                    let difficultyLabel = Text(appModel.isDifficultyHard ? "Hard Difficulty" : "Normal Difficulty")
                    Picker(selection: $appModel.isDifficultyHard, label: difficultyLabel) {
                        HStack {
                            Text("Normal Difficulty")
                            Image(systemName: "figure.stand")
                        }
                        .tag(false)

                        HStack {
                            Text("Hard Difficulty")
                            Image(systemName: "figure.fall")
                        }
                        .tag(true)
                    }
                    .pickerStyle(.menu)

                    Button("Game Menu", systemImage: "menubar.rectangle") {
                        appModel.menuVisibility = .splashScreen
                    }
                    .disabled(gamePlayState?.isMenuDisabled ?? true)

                    Button("High Score", systemImage: "numbers") {
                        appModel.menuVisibility = .highScore
                    }
                    .disabled(gamePlayState?.isMenuDisabled ?? true)
                }
            } label: {
                HStack {
                    Text("Settings")
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .environment(\.menuOrder, .fixed)
            .buttonStyle(.borderless)
            .padding([.trailing], 10)
            .hoverEffectDisabled(!menuIsExpanded)
        }
        .padding(.vertical, 10)
        .glassBackgroundEffect()
        .contentShape(.hoverEffect, .capsule)
        .hoverEffect(isEnabled: !menuIsExpanded)
        .padding(.top, 100)
        .animation(.smooth, value: menuIsExpanded)
    }
}

#Preview {
    SettingsOrnamentView()
        .environment(AppModel())
}
