/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents remote commands.
*/

import MediaPlayer

/// An enumeration that provides a collection of supported remote commands.
enum RemoteCommand: CaseIterable {
    // Playback commands.
    case play, pause, togglePlayPause, stop

    // Navigating Between Tracks commands.
    case nextTrack, previousTrack, changeRepeatMode, changeShuffleMode

    // Navigating Track Content commands.
    case changePlaybackRate, seekBackward, seekForward, skipBackward, skipForward, changePlaybackPosition

    // Rating Media Items commands.
    case rating, like, dislike

    // Bookmarking Media Items.
    case bookmark

    // Enabling Language Options commands.
    case enableLanguageOption, disableLanguageOption

    var mediaRemoteCommand: MPRemoteCommand {
        let commandCenter = MPRemoteCommandCenter.shared()

        switch self {
        case .play:
            return commandCenter.playCommand
        case .pause:
            return commandCenter.pauseCommand
        case .togglePlayPause:
            return commandCenter.togglePlayPauseCommand
        case .stop:
            return commandCenter.stopCommand
        case .nextTrack:
            return commandCenter.nextTrackCommand
        case .previousTrack:
            return commandCenter.previousTrackCommand
        case .changeRepeatMode:
            return commandCenter.changeRepeatModeCommand
        case .changeShuffleMode:
            return commandCenter.changeShuffleModeCommand
        case .changePlaybackRate:
            return commandCenter.changePlaybackRateCommand
        case .seekBackward:
            return commandCenter.seekBackwardCommand
        case .seekForward:
            return commandCenter.seekForwardCommand
        case .skipBackward:
            return commandCenter.skipBackwardCommand
        case .skipForward:
            return commandCenter.skipForwardCommand
        case .changePlaybackPosition:
            return commandCenter.changePlaybackPositionCommand
        case .rating:
            return commandCenter.ratingCommand
        case .like:
            return commandCenter.likeCommand
        case .dislike:
            return commandCenter.dislikeCommand
        case .bookmark:
            return commandCenter.bookmarkCommand
        case .enableLanguageOption:
            return commandCenter.enableLanguageOptionCommand
        case .disableLanguageOption:
            return commandCenter.disableLanguageOptionCommand
        }
    }
}
