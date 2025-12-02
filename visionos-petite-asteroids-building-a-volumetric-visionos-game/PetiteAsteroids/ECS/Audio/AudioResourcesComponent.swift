/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing sound files for playback.
*/

import RealityKit

/// A component that stores all audio resources necessary for gameplay.
struct AudioResourcesComponent: Component {

    private var keyToAudioResource: [String: AudioResource] = [:]

    /// Returns the audio resource associated with a name, if it exists.
    func get(_ name: String) -> AudioResource? {
        return keyToAudioResource[name]
    }
    
    private static func loadMenuMusic() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "menu_music",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true
            )
        )
    }
    
    private static func loadTutorialMusic() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "tutorial_music",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true,
                shouldRandomizeStartTime: true
            )
        )
    }
    
    private static func loadGameplayMusic() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "gameplay_music",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true
            )
        )
    }
    
    private static func loadOutroMusic() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "outro_music",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true
            )
        )
    }
    
    private static func loadFieryDescentSky() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "fiery_descent_sky",
            configuration: .init(
                calibration: .relative(dBSPL: -6)
            )
        )
    }
    
    private static func loadFieryDescentSFXSpatial() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "fiery_descent_SFX_spatial",
            configuration: .init(
                calibration: .relative(dBSPL: -6)
            )
        )
    }
    
    private static func loadFieryDescentSFXAmbient() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "fiery_descent_SFX_ambient_stereo",
            configuration: .init(
                calibration: .relative(dBSPL: -6)
            )
        )
    }
    
    private static func loadCrash() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "crash_1",
            configuration: .init(
                calibration: .relative(dBSPL: +6)
            )
        )
    }
    
    private static func loadCrashAmbient() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "crash_ambient",
            configuration: .init(
                calibration: .relative(dBSPL: .zero)
            )
        )
    }
    
    private static func loadRockDrop() async throws -> AudioFileGroupResource {
        var rockDropResources: [AudioFileResource] = []
        for index in 1...12 {
            let rockDrop = try await AudioFileResource(
                named: "rock_drop_\(index)",
                configuration: .init(calibration: .relative(dBSPL: -9))
            )
            rockDropResources.append(rockDrop)
        }
        return try await AudioFileGroupResource(rockDropResources)
    }
    
    private static func loadRockRoll() async throws -> AudioFileGroupResource {
        var rockRollResources: [AudioFileResource] = []
        for index in 1...15 {
            let rockRoll = try await AudioFileResource(
                named: "rock_roll_\(index)",
                configuration: .init(calibration: .relative(dBSPL: -12))
            )
            rockRollResources.append(rockRoll)
        }
        return try await AudioFileGroupResource(rockRollResources)
    }
    
    private static func loadFriendSqueak() async throws -> AudioFileGroupResource {
        var friendSqueakResources: [AudioFileResource] = []
        for index in 1...6 {
            let friendSqueak = try await AudioFileResource(
                named: "friend_squeak_\(index)",
                configuration: .init(
                    calibration: .relative(dBSPL: -6)
                )
            )
            friendSqueakResources.append(friendSqueak)
        }
        return try await AudioFileGroupResource(friendSqueakResources)
    }
    
    private static func loadFriendQuip() async throws -> AudioFileGroupResource {
        var friendQuipResources: [AudioFileResource] = []
        for index in 1...10 {
            let friendQuip = try await AudioFileResource(
                named: "friend_quip_\(index)",
                configuration: .init(
                    calibration: .relative(dBSPL: -6)
                )
            )
            friendQuipResources.append(friendQuip)
        }
        return try await AudioFileGroupResource(friendQuipResources)
    }
    
    private static func loadFriendCollect() async throws -> AudioFileGroupResource {
        var friendCollectResources: [AudioFileResource] = []
        for index in 1...4 {
            let friendCollect = try await AudioFileResource(
                named: "friend_collect_\(index)",
                configuration: .init(
                    calibration: .relative(dBSPL: -6)
                )
            )
            friendCollectResources.append(friendCollect)
        }
        return try await AudioFileGroupResource(friendCollectResources)
    }
    
    private static func loadButteTopAmbience() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "butte_top_quad",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true,
                shouldRandomizeStartTime: true,
                calibration: .relative(dBSPL: -6))
        )
    }
    
    private static func loadButteBottomAmbience() async throws -> AudioFileResource {
        try await AudioFileResource(
            named: "butte_bottom_stereo",
            configuration: .init(
                loadingStrategy: .stream,
                shouldLoop: true,
                shouldRandomizeStartTime: true,
                calibration: .relative(dBSPL: .zero)
            )
        )
    }

    /// Loads all audio resources needed for gameplay and returns an audio resources component.
    @MainActor
    public static func load() async throws -> AudioResourcesComponent {

        var audioResourcesComponent = AudioResourcesComponent()

        audioResourcesComponent.keyToAudioResource["MenuMusic"] = try await loadMenuMusic()
        audioResourcesComponent.keyToAudioResource["TutorialMusic"] = try await loadTutorialMusic()
        audioResourcesComponent.keyToAudioResource["GameplayMusic"] = try await loadGameplayMusic()
        audioResourcesComponent.keyToAudioResource["OutroMusic"] = try await loadOutroMusic()
        audioResourcesComponent.keyToAudioResource["FieryDescentSky"] = try await loadFieryDescentSky()
        audioResourcesComponent.keyToAudioResource["FieryDescentSFX_Spatial"] = try await loadFieryDescentSFXSpatial()
        audioResourcesComponent.keyToAudioResource["FieryDescentSFX_Ambient"] = try await loadFieryDescentSFXAmbient()
        audioResourcesComponent.keyToAudioResource["Crash1"] = try await loadCrash()
        audioResourcesComponent.keyToAudioResource["Crash_Ambient"] = try await loadCrashAmbient()
        audioResourcesComponent.keyToAudioResource["RockDrop"] = try await loadRockDrop()
        audioResourcesComponent.keyToAudioResource["RockRoll"] = try await loadRockRoll()
        audioResourcesComponent.keyToAudioResource["FriendSqueak"] = try await loadFriendSqueak()
        audioResourcesComponent.keyToAudioResource["FriendQuip"] = try await loadFriendQuip()
        audioResourcesComponent.keyToAudioResource["FriendCollect"] = try await loadFriendCollect()
        audioResourcesComponent.keyToAudioResource["ButteTopAmbience"] = try await loadButteTopAmbience()
        audioResourcesComponent.keyToAudioResource["ButteBottomAmbience"] = try await loadButteBottomAmbience()
        audioResourcesComponent.keyToAudioResource["ButteRiseAndFadeIn"] = try await AudioFileResource(named: "butte_rise_and_fade_in_music")
        audioResourcesComponent.keyToAudioResource["Checkpoint1"] = try await AudioFileResource(named: "checkpoint_1")
        audioResourcesComponent.keyToAudioResource["Checkpoint2"] = try await AudioFileResource(named: "checkpoint_2")
        audioResourcesComponent.keyToAudioResource["Checkpoint3"] = try await AudioFileResource(named: "checkpoint_3")
        audioResourcesComponent.keyToAudioResource["Checkpoint4"] = try await AudioFileResource(named: "checkpoint_4")
        audioResourcesComponent.keyToAudioResource["Checkpoint5"] = try await AudioFileResource(named: "checkpoint_5")
        audioResourcesComponent.keyToAudioResource["Checkpoint6"] = try await AudioFileResource(named: "checkpoint_6")
        audioResourcesComponent.keyToAudioResource["Checkpoint7"] = try await AudioFileResource(named: "checkpoint_7")
        audioResourcesComponent.keyToAudioResource["Checkpoint8"] = try await AudioFileResource(named: "checkpoint_8")
        audioResourcesComponent.keyToAudioResource["Checkpoint9"] = try await AudioFileResource(named: "checkpoint_9")

        return audioResourcesComponent
    }
}
