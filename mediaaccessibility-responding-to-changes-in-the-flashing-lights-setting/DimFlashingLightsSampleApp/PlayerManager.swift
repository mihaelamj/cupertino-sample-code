/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that loads the video and manages the video player.
*/

import SwiftUI
import AVKit
import MediaAccessibility

class PlayerManager: ObservableObject {
    
    // Dim Flashing Lights setting state.
    @Published var dimFlashingLightsStatus = false
    
    // Video playback state.
    @Published var playbackPercentage: Double = 0
    @Published var playbackDuration: CFAbsoluteTime = 0
    
    var player: AVPlayer
        
    /// - Tag: RegisterForNotification
    init() {
        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else {
            fatalError("No video file.")
        }
        
        player = AVPlayer(url: url)

        Task {
            do {
                if let item = player.currentItem {
                    let duration = try await item.asset.load(.duration)
                    DispatchQueue.main.async {
                        self.playbackDuration = duration.seconds
                    }
                }
            } catch {
                fatalError("Unable to retrieve video duration.")
            }
        }
        
        // Configures the video player to report its current playback progress.
        // This information makes it possible to draw the custom playback indicator
        // in the corresponding position on top of the timeline view.
        player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1,
                                preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: DispatchQueue.main) { [weak self] time in
                guard let self, self.dimFlashingLightsStatus else {
                    return
                }
                
                self.playbackPercentage = time.seconds / self.playbackDuration
        }

        // Sets the initial `dimFlashingLightsStatus` to the current value of
        // the Dim Flashing Light setting.
        dimFlashingLightsStatus = MADimFlashingLightsEnabled()
        
        // Registers for the system notification that posts when the value of
        // the Dim Flashing Lights setting changes.
        NotificationCenter.default.addObserver(self,
            selector: #selector(dimFlashingLightsChanged),
            name: kMADimFlashingLightsChangedNotification as NSNotification.Name,
            object: nil)
    }
    
    // Receives a notification when the value of the Dim Flashing Lights
    // setting changes.
    /// - Tag: SettingChanged
    @objc
    func dimFlashingLightsChanged(_ notification: Notification) {
        // Updates `dimFlashingLightsStatus` to the new value of the
        // Dim Flashing Light setting.
        dimFlashingLightsStatus = MADimFlashingLightsEnabled()
    }
}
