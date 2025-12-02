/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The player to track player states.
*/

import AVFoundation
import Observation
import Combine
import os
import AVRouting

// Class that represents the player to keep track of player states.
@Observable
class PlayerState {
    let assetURL: URL
    let playerID: String
    let networkPriority: NetworkPriority
    var playerRate: Float = 0
    var rateObserver: NSKeyValueObservation?
    var externalPlaybackActiveObserver: NSKeyValueObservation?
    let routingPlaybackArbiter: AVRoutingPlaybackArbiter = AVRoutingPlaybackArbiter.shared()
    var isFocusPlayer = false
    var isFullScreen = false
    var shouldBeHidden = false
    
    private let queue = DispatchQueue(label: "com.apple.AVFoundation.MultiviewPlaybackSampleApp.PlayerState.queue")
        
    // Create the player.
    @ObservationIgnored
    lazy var player: AVPlayer = {
        let asset = AVURLAsset(url: assetURL)
        
        var playerItem = AVPlayerItem(asset: asset)
        var player = AVPlayer()
        
        player.networkResourcePriority = networkPriority.asAVFNetworkPriority()
        player.replaceCurrentItem(with: playerItem)
        player.volume = 1.0
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        
        return player
    }()
    
    // MARK: - Life cycle
    
    init(assetURL: String, assetID: UUID, networkPriority: NetworkPriority) {
        self.assetURL = URL(string: assetURL)!
        
        // Create asset logging identifier.
        playerID = assetID.uuidString
        
        self.networkPriority = networkPriority
        
        beginObservingEvents()
        
        let audioSession = AVAudioSession.sharedInstance()
#if os(iOS)
        do {
            try audioSession.setCategory(.playback, mode: .default, policy: .longFormVideo)
        } catch {
            Logger.general.log("[PlayerState] [\(self.playerID)] Failed to set the audio session configuration")
        }
#endif
        
        Logger.general.log("[PlayerState] [\(self.playerID)] Initialize player state for player \(self.player)")
    }
    
    func connectToAVFCoordinationMedium(coordinationMedium: AVPlaybackCoordinationMedium) {
        do {
            try player.playbackCoordinator.coordinate(using: coordinationMedium)
            Logger.general.log("[PlayerState] [\(self.playerID)] Connect to AVF coordination medium succeeded")
        } catch let error {
            Logger.general.log("[PlayerState] [\(self.playerID)] Connect to AVF coordination medium failed with error \(error)")
        }
    }
    
    func beginObservingEvents() {
        // Observer for the player rate.
        rateObserver = player.observe(\.rate, changeHandler: { [weak self] player, change in
            if let self = self {
                playerRate = player.rate
            }
        })

        // Observer for external playback status.
        externalPlaybackActiveObserver = player.observe(\.isExternalPlaybackActive, changeHandler: { [weak self] player, change in
            if let self = self {
                shouldBeHidden = player.isExternalPlaybackActive
            }
        })
    }
    
    // MARK: - Playback
    
    // Set a rate on the player.
    func setRate(rate: Float) {
        Logger.general.log("[PlayerState] [\(self.playerID)] Set rate \(rate)")
        
        player.rate = rate
    }
    
    // Play with a default rate of 1.
    func play() {
        Logger.general.log("[PlayerState] [\(self.playerID)] Play")
        
        player.play()
    }
    
    // Pause the player.
    func pause() {
        Logger.general.log("[PlayerState] [\(self.playerID)] Pause")
        
        player.rate = 0
    }
    
    // Seek by delta time (in seconds).
    func seek(by delta: Double) {
        let targetTime = player.currentTime().seconds + delta
        Logger.general.log("[PlayerState] [\(self.playerID)] Seeking to time \(targetTime)")
        
        // Seek to specified time.
        player.seek(to: CMTimeMakeWithSeconds(targetTime, preferredTimescale: 1),
                         toleranceBefore: .zero,
                         toleranceAfter: .zero)
    }
    
    // Mute or unmute the player.
    func mute(isMuted: Bool) {
        Logger.general.log("[PlayerState] [\(self.playerID)] \(isMuted ? "Muting" : "Unmuting")")
        
        player.isMuted = isMuted
    }
    
    // Toggle focus using the `AVRoutingPlaybackArbiter` API
    func toggleFocus(isFocused: Bool) {
        isFocusPlayer = isFocused
        
        if isFocused {
            Logger.general.log("[PlayerState] [\(self.playerID)] Setting preferred participant")
#if os(tvOS)
            routingPlaybackArbiter.preferredParticipantForNonMixableAudioRoutes = player
#endif
            routingPlaybackArbiter.preferredParticipantForExternalPlayback = player
        }
        
        // Set external playback status for AirPlay.
        player.allowsExternalPlayback = isFocused

        // Mute or unmute the player.
        mute(isMuted: !isFocused)
    }
    
    // Set network priority to a specified value.
    func setNetworkPriority(networkPriorityValue: Int) {
        Logger.general.log("[PlayerState] [\(self.playerID)] Setting network priority to \(networkPriorityValue)")
        
        var networkPriority: AVPlayer.NetworkResourcePriority = .default
        switch networkPriorityValue {
        case 0:
            networkPriority = .low
        case 1:
            networkPriority = .default
        case 2:
            networkPriority = .high
        default:
            networkPriority = .default
        }
        
        player.networkResourcePriority = networkPriority
    }
    
    // Update the player's full screen status.
    func updateFullScreenStatus(isFullScreen: Bool) {
        Logger.general.log("[PlayerState] [\(self.playerID)] Update full screen status: \(isFullScreen)")
        
        self.isFullScreen = isFullScreen
    }
    
    func invalidate() {
        Task { @MainActor in
            Logger.general.info("[PlayerState] [\(self.playerID)] Cleaning up player state")
                        
            do {
                try player.playbackCoordinator.coordinate(using: nil)
            } catch let error {
                Logger.general.log("[PlayerState] [\(self.playerID)] Disconnect from AVF coordination medium failed with error \(error)")
            }
                            
            rateObserver?.invalidate()
            rateObserver = nil
            
            externalPlaybackActiveObserver?.invalidate()
            externalPlaybackActiveObserver = nil
            
            player.replaceCurrentItem(with: nil)
        }
    }
}
