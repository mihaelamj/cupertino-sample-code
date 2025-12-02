/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing the player's top scores.
*/

import RealityKit
import SwiftUI

struct HighScoreView: View {
    
    @AppStorage(PersistentData.playerRunsKey) var runsData: Data?
    @AppStorage(PersistentData.lastRunKey) var lastRunID: String?
    @AppStorage(PersistentData.rockFriendsCollectedKey) var rockFriendsCollectedMapData: Data?
    
    @Environment(AppModel.self) private var appModel
    
    private var runs: [PlayerRun] {
        guard let runsData,
            let playerRuns = try? JSONDecoder().decode([PlayerRun].self, from: runsData) else { return [] }
        return playerRuns
    }
    
    private static let timeFormat = Duration.TimeFormatStyle.time(pattern: .minuteSecond(padMinuteToLength: 2))
    
    private var rockFriendsCollectedMap: [String: Bool] {
        guard let rockFriendsCollectedMapData,
              let rockFriendsCollectedMap = try? JSONDecoder().decode([String: Bool].self, from: rockFriendsCollectedMapData) else {
            return [:]
        }
        return rockFriendsCollectedMap
    }

    let listScrollFade: LinearGradient = LinearGradient(
        stops: [
            .init(color: Color.black.opacity(0), location: 0.0),
            .init(color: Color.black, location: 0.1),
            .init(color: Color.black, location: 0.9),
            .init(color: Color.black.opacity(0), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            VStack {
                TitleView(title: "HIGH SCORE")

                Spacer(minLength: 30)
                
                FriendsView(rockFriendsCollectedMap: rockFriendsCollectedMap)
                    .padding(.horizontal, 30)
                
                Spacer(minLength: 50)
                
                List {
                    Section(content: {
                        ForEach(runs) { run in
                            let isPostGame = appModel.root.observable.components[GamePlayStateComponent.self] == .postGame
                            let isLastRun = run.id.uuidString == lastRunID
                            HStack {
                                if let place = runs.firstIndex(of: run) {
                                    Text("\(String(place + 1))")
                                        .frame(maxWidth: .infinity)
                                        .font(.system(size: 22))
                                }
                                
                                Text(Duration.seconds(Double(run.duration)), format: Self.timeFormat)
                                    .frame(maxWidth: .infinity)
                                
                                Text(String(run.rockFriendsCollected))
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 22))
                                
                                Text(String(run.isDifficultyHard == true ? "Hard" : "Normal"))
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 22))
                            }
                            .bold(isLastRun)
                            .foregroundColor(!isPostGame || isLastRun ? Color.black : Color.gray)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }, header: {
                        HStack {
                            Text("Ranking")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 24))
                            
                            Text("Time")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 24))
                            
                            Text("Friends Found")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 24))
                            
                            Text("Difficulty")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 24))
                        }
                        .bold()
                        .padding(.top, 15)
                    })
                }
                .mask {
                    VStack(spacing: 0) {
                        listScrollFade
                    }
                }
                .padding(.bottom, 15)

                if appModel.root.observable.components[GamePlayStateComponent.self] == .postGame {
                    Button("Let's go again!") {
                        appModel.menuVisibility = .hidden
                        appModel.root.components.set(GamePlayStateComponent.starting)
                    }
                    .buttonStyle(AttachmentButton())
                }
            }
            .attachment()
            .ignoresSafeArea()
        }
    }
}

#Preview {
    let previewUserDefaults: UserDefaults = {
        let userDefaults = UserDefaults(suiteName: "preview_high_score_view")!
        let lastRun = PlayerRun(35.32, 0, true)
        let previewPlayerRuns = [
            lastRun,
            PlayerRun(67.32, 0, true),
            PlayerRun(69.43, 0, false),
            PlayerRun(80.12, 0, false),
            PlayerRun(81.92, 0, false),
            PlayerRun(84.56, 0, true)
        ]
        userDefaults.set(lastRun.id.uuidString, forKey: PersistentData.lastRunKey)
        userDefaults.set(previewPlayerRuns, forKey: PersistentData.playerRunsKey)
        return userDefaults
    }()

    HighScoreView()
        .environment(AppModel())
        .frame(maxWidth: 700, maxHeight: 450)
        .defaultAppStorage(previewUserDefaults)
}
