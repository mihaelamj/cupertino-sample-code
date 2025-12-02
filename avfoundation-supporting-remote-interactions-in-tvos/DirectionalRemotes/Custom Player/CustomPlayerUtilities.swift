/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Models for the custom player that represent player feedback,
        states, and play modes.
*/

import Foundation

/// An enumeration that provides the representation of the different trick play modes.
enum TrickPlayMode {
    case fastForward, rewind
}

/// An enumeration that provides the feedback types supported by the custom player.
enum CustomPlayerFeedbackType {
    case shortLived
    case lasting
}

/// An enumeration that provides a collection of the internal states of  the `CustomPlayer` separate from
/// the state of the `AVPlayer`.
enum CustomPlayerState {
    case stopped, playing, paused
    case fastForwarding, rewinding

    /// Maps the custom player internal state to the associated
    /// `RemoteEvent`.
    var associatedRemoteEvent: RemoteEvent {
        switch self {
        case .stopped:
            return .stop
        case .playing:
            return .play
        case .paused:
            return .pause
        case .fastForwarding:
            return .fastForward
        case .rewinding:
            return .rewind
        }
    }
}
