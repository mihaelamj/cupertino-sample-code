/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that persists data between game sessions, like the player's top runs.
*/

import SwiftUI
import OSLog

@MainActor
class PersistentData {
    static let playerRunsKey: String = "playerRuns"
    static let lastRunKey: String = "lastRun"
    static let skipTutorialKey: String = "skipTutorial"
    static let rockFriendsCollectedKey: String = "rockFriendsCollected"

    private var lastRunID: UUID?
    private var playerRuns: [PlayerRun] = []
    private var skipIntro: Bool = false
    
    // A dictionary that records which rock friends the player finds in the level across all runs.
    private var rockFriendsCollectedMap: [String: Bool] = [
        "RockPickup_1/RockFriend_Bowie": false,
        "RockPickup_2/RockFriend_Cavity": false,
        "RockPickup_3/RockFriend_Curvy": false,
        "RockPickup_4/RockFriend_Dottie": false,
        "RockPickup_5/RockFriend_Dubz": false,
        "RockPickup_6/RockFriend_Fleck": false,
        "RockPickup_7/RockFriend_Moon": false,
        "RockPickup_8/RockFriend_Rub": false,
        "RockPickup_9/RockFriend_Striped": false,
        "RockPickup_10/RockFriend_Wave": false,
        "RockPickup_11/RockFriend_Bowie": false,
        "RockPickup_12/RockFriend_Cavity": false
    ]
    
    /// Get the most-recent player run if it's saved in the top runs.
    var lastRun: PlayerRun? {
        playerRuns.first(where: { $0.id == lastRunID })
    }
    
    init() {
        // Read the player's run data.
        if let playerRunsData = UserDefaults.standard.data(forKey: PersistentData.playerRunsKey),
           let decodedPlayerRuns = try? JSONDecoder().decode([PlayerRun].self, from: playerRunsData) {
            logger.info("loaded saved data for player runs: \(playerRunsData)")
            playerRuns = decodedPlayerRuns
        } else {
            logger.info("no saved run data found")
            playerRuns = .init()
        }
        
        // Read the skip tutorial flag.
        if let skipTutorialData = UserDefaults.standard.data(forKey: PersistentData.skipTutorialKey),
           let decodedSkipTutorial = try? JSONDecoder().decode(Bool.self, from: skipTutorialData) {
            logger.info("loaded saved data for skip tutorial flag: \(skipTutorialData): do skip: \(decodedSkipTutorial)")
            skipIntro = decodedSkipTutorial
        } else {
            logger.info("no saved data for skip tutorial flag")
        }
        // Read the last run ID.
        if let lastRunString = UserDefaults.standard.string(forKey: PersistentData.lastRunKey) {
            lastRunID = UUID(uuidString: lastRunString)
        } else {
            logger.info("no saved data for last run")
        }
        // Read the rock-friends-collected map, which tracks which rock friends the player finds in the level.
        if let rockFriendsCollectedMapData = UserDefaults.standard.data(forKey: PersistentData.rockFriendsCollectedKey),
           let decodedRockFriendsCollectedMap = try? JSONDecoder().decode([String: Bool].self, from: rockFriendsCollectedMapData) {
            logger.info("loaded rock friends collected map data: \(decodedRockFriendsCollectedMap)")
            rockFriendsCollectedMap = decodedRockFriendsCollectedMap
        } else {
            logger.info("no saved data found for rock friends collected map.")
        }
    }
    
    /// Attempt to record a run (the app saves only the best times).
    public func recordRun(duration: Float, rockFriendsCollected: [CollectedRockFriend], isDifficultyHard: Bool) {
        // Create a player run object.
        let playerRun = PlayerRun(duration, rockFriendsCollected.count, isDifficultyHard)
        
        // Record the last run ID so the system can identify the run in the high-score view.
        lastRunID = playerRun.id
        
        // Add the player run to the list of runs.
        playerRuns.append(playerRun)
        
        // Sort the player runs using the `sortRuns` function.
        playerRuns.sort(by: sortRuns)
        
        // Discard any player runs that don't make the cut.
        if playerRuns.count > GameSettings.maxPlayerRunsRecorded {
            playerRuns.remove(at: GameSettings.maxPlayerRunsRecorded)
        }
        
        // Record the individual rock friends the player finds.
        for rockFriend in rockFriendsCollected {
            guard rockFriendsCollectedMap.contains(where: { $0.key == rockFriend.name }) else { continue }
            rockFriendsCollectedMap[rockFriend.name] = true
        }
        
        // Save all data to disk.
        save()
    }
    
    /// Encode persistent data into JSON and write the data to `UserDefaults`.
    public func save() {
        if let playerRunsData = try? JSONEncoder().encode(playerRuns) {
            UserDefaults.standard.set(playerRunsData, forKey: PersistentData.playerRunsKey)
        }
        
        if let skipTutorialData = try? JSONEncoder().encode(skipIntro) {
            UserDefaults.standard.set(skipTutorialData, forKey: PersistentData.skipTutorialKey)
        }
        
        if let lastRunID {
            UserDefaults.standard.setValue(lastRunID.uuidString, forKey: PersistentData.lastRunKey)
        }
        
        if let rockFriendsCollectedData = try? JSONEncoder().encode(rockFriendsCollectedMap) {
            UserDefaults.standard.set(rockFriendsCollectedData, forKey: PersistentData.rockFriendsCollectedKey)
        }
    }
    
    /// Set the skip tutorial flag and save all persistent data.
    public func setSkipTutorial(doSkip: Bool) {
        skipIntro = doSkip
        save()
    }
    
    /// Check whether the player needs to skip the intro sequence.
    public func checkSkipIntro() -> Bool {
        return skipIntro
    }
    
    /// Sort the player runs based on their duration.
    private func sortRuns(runA: PlayerRun, runB: PlayerRun) -> Bool {
        return runA.duration < runB.duration
    }
}

/// A serializable structure containing data about an individual player run.
public struct PlayerRun: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID = UUID()
    public var duration: Float = 0
    public var rockFriendsCollected: Int = 0
    let isDifficultyHard: Bool
    init(_ duration: Float, _ rockFriendsCollected: Int, _ isDifficultyHard: Bool = false) {
        self.duration = duration
        self.rockFriendsCollected = rockFriendsCollected
        self.isDifficultyHard = isDifficultyHard
    }
}
