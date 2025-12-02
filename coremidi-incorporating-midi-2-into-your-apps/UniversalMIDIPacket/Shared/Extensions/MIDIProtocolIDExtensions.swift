/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension for the MIDI protocol identifier.
*/

import CoreMIDI

extension MIDIProtocolID: CustomStringConvertible {
    public var description: String {
        switch self {
        case ._1_0:
            return "MIDI-1UP"
        case ._2_0:
            return "MIDI 2.0"
        default:
            return "N/A"
        }
    }
}
