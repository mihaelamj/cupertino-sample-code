/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension for real-time games that handles communication between players using voice chat.
*/

import Foundation
import GameKit
import SwiftUI

extension RealTimeGame {
    
    /// Starts a voice chat between players.
    /// - Tag:startVoiceChat
    func startVoiceChat() {
        // Handle an unknown, connected, or disconnected player state.
        /// - Tag:voiceChatChangeHandler
        let voiceChatChangeHandler = { (player: GKPlayer, state: GKVoiceChat.PlayerState) -> Void in
            switch state {
            case GKVoiceChat.PlayerState.connected:
                print("Player chat connnected.")
            case GKVoiceChat.PlayerState.disconnected:
                print("Player chat disconnnected.")
            case GKVoiceChat.PlayerState.speaking:
                print("Player speaking.")
            case GKVoiceChat.PlayerState.silent:
                print("Player silent.")
            case GKVoiceChat.PlayerState.connecting:
                print("Player connecting.")
            @unknown default:
                print("Player unknown state.")
            }
        }
        
        if voiceChat == nil {
            // Create the voice chat object.
            voiceChat = myMatch?.voiceChat(withName: "RealTimeGameChannel")
        }

        // Exit early if the app can't start a voice chat session.
        guard let voiceChat = voiceChat else { return }

        // Handle an unknown, connected, or disconnected player state.
        voiceChat.playerVoiceChatStateDidChangeHandler = voiceChatChangeHandler

        // Set the audio volume.
        voiceChat.volume = 0.5

        // Activate the shared audio session.
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setActive(true, options: [])
        } catch {
            print("AVAudioSession error: \(error.localizedDescription).")
        }

        voiceChat.start()
        voiceChat.isActive = true
    }
    
    /// Stops the voice chat.
    /// - Tag:stopVoiceChat
    func stopVoiceChat() {
        // Stop the voice chat.
        voiceChat?.stop()
        voiceChat = nil

        // Deactivate the shared audio session.
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setActive(false, options: [])
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    /// Enables the microphone.
    /// - Tag:muteVoiceChat
    func muteVoiceChat() {
        voiceChat?.setPlayer(GKLocalPlayer.local, muted: true)
    }
    
    /// Disables the microphone.
    /// - Tag:unmuteVoiceChat
    func unmuteVoiceChat() {
        voiceChat?.setPlayer(GKLocalPlayer.local, muted: false)
    }
    
    /// Sets the microphone volume.
    ///  - Tag:voiceChat
    func voiceChat(volume: Float) {
        voiceChat?.volume = volume
    }
}
