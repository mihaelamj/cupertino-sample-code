/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on AVPlayer.TimeControlStatus.
*/

import AVFoundation

extension AVPlayer.TimeControlStatus {
    var isPaused: Bool {
        self == .paused
    }

    var isPlaying: Bool {
        self == .playing
    }

    var isWaitingToPlayAtSpecifiedRate: Bool {
        self == .waitingToPlayAtSpecifiedRate
    }
}
