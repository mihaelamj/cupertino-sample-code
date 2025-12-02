/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The controller manages the app's active SharePlay session.
*/

import GroupActivities
import Observation

@Observable @MainActor
final class SessionController {
    let session: GroupSession<GuessTogetherActivity>
    let messenger: GroupSessionMessenger
    let systemCoordinator: SystemCoordinator
    
    var game: GameModel {
        get {
            gameSyncStore.game
        }
        set {
            if newValue != gameSyncStore.game {
                gameSyncStore.game = newValue
                shareLocalGameState(newValue)
            }
        }
    }
    
    var gameSyncStore = GameSyncStore() {
        didSet {
            gameStateChanged()
        }
    }

    var players = [Participant: PlayerModel]() {
        didSet {
            if oldValue != players {
                updateCurrentPlayer()
                updateLocalParticipantRole()
            }
        }
    }
    
    var localPlayer: PlayerModel {
        get {
            players[session.localParticipant]!
        }
        set {
            if newValue != players[session.localParticipant] {
                players[session.localParticipant] = newValue
                shareLocalPlayerState(newValue)
            }
        }
    }
    
    init?(_ groupSession: GroupSession<GuessTogetherActivity>, appModel: AppModel) async {
        guard let groupSystemCoordinator = await groupSession.systemCoordinator else {
            return nil
        }

        session = groupSession

        // Create the group session messenger for the session controller, which it uses to keep the game in sync for all participants.
        messenger = GroupSessionMessenger(session: session)

        systemCoordinator = groupSystemCoordinator

        // Create a representation of the local participant.
        localPlayer = PlayerModel(
            id: session.localParticipant.id,
            name: appModel.playerName
        )
        appModel.showPlayerNameAlert = localPlayer.name.isEmpty
        
        observeRemoteParticipantUpdates()
        configureSystemCoordinator()
        
        session.join()
    }
    
    func updateSpatialTemplatePreference() {
        switch game.stage {
            case .categorySelection:
                systemCoordinator.configuration.spatialTemplatePreference = .sideBySide
            case .teamSelection:
                systemCoordinator.configuration.spatialTemplatePreference = .custom(TeamSelectionTemplate())
            case .inGame:
                systemCoordinator.configuration.spatialTemplatePreference = .custom(GameTemplate())
        }
    }
    
    func updateLocalParticipantRole() {
        // Set and unset the participant's spatial template role based on updating game state.
        switch game.stage {
            case .categorySelection:
                systemCoordinator.resignRole()
            case .teamSelection:
                switch localPlayer.team {
                case .none:
                    systemCoordinator.resignRole()
                case .blue:
                    systemCoordinator.assignRole(TeamSelectionTemplate.Role.blueTeam)
                case .red:
                    systemCoordinator.assignRole(TeamSelectionTemplate.Role.redTeam)
                }
            case .inGame:
                if localPlayer.isPlaying {
                    systemCoordinator.assignRole(GameTemplate.Role.player)
                } else if let currentPlayer {
                    if currentPlayer.team == localPlayer.team {
                        systemCoordinator.assignRole(GameTemplate.Role.activeTeam)
                    } else {
                        systemCoordinator.resignRole()
                    }
                }
        }
    }
    
    func configureSystemCoordinator() {
        // Let the system coordinator show each players' spatial Persona in the immersive space.
        systemCoordinator.configuration.supportsGroupImmersiveSpace = true
        
        Task {
            // Wait for gameplay updates from participants.
            for await localParticipantState in systemCoordinator.localParticipantStates {
                localPlayer.seatPose = localParticipantState.seat?.pose
            }
        }
    }

    func enterTeamSelection() {
        game.stage = .teamSelection
        game.currentRoundEndTime = nil
        game.turnHistory.removeAll()
    }
    
    func joinTeam(_ team: PlayerModel.Team?) {
        localPlayer.team = team
    }
    
    func startGame() {
        game.stage = .inGame(.beforePlayersTurn)
    }
    
    func beginTurn() {
        nextCard(successful: false)
        
        // Set the new turn game state.
        game.stage = .inGame(.duringPlayersTurn)
        game.currentRoundEndTime = .now.addingTimeInterval(30)
        
        // Wait thirty seconds before ending the current turn.
        let sleepUntilTime = ContinuousClock.now.advanced(by: .seconds(30))
        Task {
            try await Task.sleep(until: sleepUntilTime)
            if case .inGame(.duringPlayersTurn) = game.stage {
                game.stage = .inGame(.afterPlayersTurn)
            }
        }
    }
    
    func nextCard(successful: Bool) {
        guard localPlayer.isPlaying else {
            return
        }
        
        if successful {
            localPlayer.score += 1
        }
        
        // Retrieve a random secret phrase from the phrase manager.
        let nextPhrase = PhraseManager.shared.randomPhrase(
            excludedCategories: game.excludedCategories,
            usedPhrases: game.usedPhrases
        )
        
        game.usedPhrases.insert(nextPhrase)
        game.currentPhrase = nextPhrase
    }
    
    func endTurn() {
        guard game.stage.isInGame, localPlayer.isPlaying else {
            return
        }
        
        game.turnHistory.append(session.localParticipant.id)
        game.currentRoundEndTime = nil
        game.stage = .inGame(.beforePlayersTurn)
        
        if playerAfterLocalParticipant != localPlayer {
            localPlayer.isPlaying = false
        }
    }
    
    func endGame() {
        game.stage = .categorySelection
    }
    
    func gameStateChanged() {
        if game.stage == .categorySelection {
            localPlayer.isPlaying = false
            localPlayer.score = 0
        }
        
        updateSpatialTemplatePreference()
        updateCurrentPlayer()
        updateLocalParticipantRole()
    }
}
