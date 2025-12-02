/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation that video content is ready to be played.
*/

import Foundation

struct PlaybackReadiness {
    private let isPlayerItemReadyToPlay: Bool
    private let isVideoReadyToRender: Bool

    var isReady: Bool {
        isPlayerItemReadyToPlay && isVideoReadyToRender
    }

    init(isPlayerItemReadyToPlay: Bool = false, isVideoReadyToRender: Bool = false) {
        self.isPlayerItemReadyToPlay = isPlayerItemReadyToPlay
        self.isVideoReadyToRender = isVideoReadyToRender
    }
}

extension PlaybackReadiness {
    static let `default` = PlaybackReadiness()

    func with(isPlayerItemReadyToPlay: Bool) -> PlaybackReadiness {
        guard isPlayerItemReadyToPlay != self.isPlayerItemReadyToPlay else { return self }

        return PlaybackReadiness(
            isPlayerItemReadyToPlay: isPlayerItemReadyToPlay,
            isVideoReadyToRender: self.isVideoReadyToRender
        )
    }

    func with(isVideoReadyToRender: Bool) -> PlaybackReadiness {
        guard isVideoReadyToRender != self.isVideoReadyToRender else { return self }

        return PlaybackReadiness(
            isPlayerItemReadyToPlay: self.isPlayerItemReadyToPlay,
            isVideoReadyToRender: isVideoReadyToRender
        )
    }
}
