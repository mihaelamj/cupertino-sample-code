/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages audio playback.
*/

import AVFoundation
import Combine
import SwiftUI

@Observable class AudioPlayerViewModel {
    
    // The AVPlayer object.
    var player: AVPlayer?
    
    // The time observer variable.
    private var timeObserver: Any?
    
    // A Boolean value that indicates player object the app is playing.
    var isPlaying: Bool = false

    // The current time variable.
    var currentTime: Double = 0
    
    // The time duration variable.
    var duration: Double = 1
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadAudio(from url: URL) {
       let playerItem = AVPlayerItem(url: url)
       player = AVPlayer(playerItem: playerItem)

       // Observe duration of time.
       playerItem.publisher(for: \.duration)
           .compactMap { $0.isIndefinite ? nil : $0.seconds }
           .receive(on: DispatchQueue.main)
           .sink { [weak self] seconds in
               self?.duration = seconds
           }
           .store(in: &cancellables)
    
        addPeriodicTimeObserver()
        
    }

    // The function to play the audio.
    func play() {
        player?.play()
        isPlaying = true
    }

    // The function to pause the audio.
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    // The function to fast forward the audio player by five seconds.
    func skipAudioFiveSeconds() {
        if let player {
            let playerCurrentTime = player.currentTime().seconds
            let newTime = playerCurrentTime + 5
            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        }
    }
    
    // The function to rewind the audio player by five seconds.
    func rewindAudioFiveSeconds() {
        if let player {
            let playerCurrentTime = player.currentTime().seconds
            let newTime = playerCurrentTime - 5
            player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        }
    }

    // The function to seek the audio by a specific cmtime.
    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    func seekToAndPlay(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        player?.play()
        isPlaying = true
    }

    // The function to add a time observer for the AVPlayer object.
    private func addPeriodicTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    deinit {
        if let token = timeObserver {
            player?.removeTimeObserver(token)
        }
    }
}
