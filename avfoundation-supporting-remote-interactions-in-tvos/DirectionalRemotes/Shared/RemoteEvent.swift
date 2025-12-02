/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents remote events.
*/

import Foundation

/// An enumeration that provides a collection of remote events as well as their `String` representation in
/// English.
enum RemoteEvent: String, CaseIterable {

    case channelUp = "Channel Up"
    case channelDown = "Channel Down"

    case guide = "Guide"

    case playPause = "PlayPause"
    case select = "Select"

    case dPadLeft = "D-Pad Left"
    case dPadUp = "D-Pad Up"
    case dPadRight = "D-Pad Right"
    case dPadDown = "D-Pad Down"

    case swipeLeft = "Swipe Left"
    case swipeUp = "Swipe Up"
    case swipeRight = "Swipe Right"
    case swipeDown = "Swipe Down"

    case play = "Play"
    case pause = "Pause"
    case stop = "Stop"

    case rewind = "Rewind"
    case fastForward = "Fast Forward"

    case skipBackward = "Skip Backward"
    case skipForward = "Skip Forward"

    case previousTrack = "Previous Track"
    case nextTrack = "Next Track"

}
