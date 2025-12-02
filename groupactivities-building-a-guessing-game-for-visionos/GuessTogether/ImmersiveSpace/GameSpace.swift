/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An immersive space the game presents during the in-game stages.
*/

import SwiftUI

struct GameSpace: Scene {
    @Environment(AppModel.self) var appModel
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    static let spaceID = "GameSpace"
    
    var body: some Scene {
        ImmersiveSpace(id: Self.spaceID) {
            ZStack {
                PhraseDeckPodiumView()
                SeatScoresView()
            }
            .onAppear {
                appModel.isImmersiveSpaceOpen = true
            }
            .onDisappear {
                appModel.isImmersiveSpaceOpen = false
            }
        }
        .onChange(of: appModel.sessionController?.game.stage, updateImmersiveSpaceState)
    }
    
    /// Opens or dismisses the app's immersive space based on the game's current and previous states.
    ///
    /// - Parameters:
    ///     - oldActivityStage: The app's previous activity stage.
    ///     - newActivityStage: The app's current stage.
    func updateImmersiveSpaceState(
        oldActivityStage: GameModel.ActivityStage?,
        newActivityStage: GameModel.ActivityStage?
    ) {
        let wasInGame = oldActivityStage?.isInGame ?? false
        let isInGame = newActivityStage?.isInGame ?? false
        
        guard wasInGame != isInGame else {
            return
        }
        
        Task {
            if isInGame && !appModel.isImmersiveSpaceOpen {
                await openImmersiveSpace(id: Self.spaceID)
            } else if appModel.isImmersiveSpaceOpen {
                await dismissImmersiveSpace()
            }
        }
    }
}
