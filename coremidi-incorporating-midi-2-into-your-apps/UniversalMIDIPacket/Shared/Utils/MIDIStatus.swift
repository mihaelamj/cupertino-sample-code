/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration representing the MIDI status byte.
*/

import Foundation

enum MIDIMessageStatus: Hashable, CustomStringConvertible, CaseIterable {
    
    static var allCases: [MIDIMessageStatus] {
        [
            .none,
            .noteOn(._1_0),
            .noteOn(._2_0),
            .noteOff(._2_0),
            .controlChange(._2_0),
            .programChange(._2_0)
        ]
    }
    
    case none
    case noteOn(_ protocol: MIDIProtocolID)
    case noteOff(_ protocol: MIDIProtocolID)
    case controlChange(_ protocol: MIDIProtocolID)
    case programChange(_ protocol: MIDIProtocolID)

    var byteValue: UInt8 {
        switch self {
        case .none:
            return 0x0
        case .noteOn:
            return 0x9
        case .noteOff:
            return 0x8
        case .controlChange:
            return 0xB
        case .programChange:
            return 0xC
        }
    }
    
    var description: String {
        switch self {
        // Note On
        case .noteOn(._1_0):
            return "Note On (" + MIDIProtocolID._1_0.description + ")"
        case .noteOn(._2_0):
            return "Note On (" + MIDIProtocolID._2_0.description + ")"
        // Note Off
        case .noteOff(._1_0):
            return "Note Off (" + MIDIProtocolID._1_0.description + ")"
        case .noteOff(._2_0):
            return "Note Off (" + MIDIProtocolID._2_0.description + ")"
        // Control Change
        case .controlChange(._1_0):
            return "Control Change (" + MIDIProtocolID._1_0.description + ")"
        case .controlChange(._2_0):
            return "Control Change (" + MIDIProtocolID._2_0.description + ")"
        // Program Change
        case .programChange(._1_0):
            return "Program Change (" + MIDIProtocolID._1_0.description + ")"
        case .programChange(._2_0):
            return "Program Change (" + MIDIProtocolID._2_0.description + ")"
        // None
        default:
            return "None"
        }
    }
    
    init(byteValue: UInt8, protocolID: MIDIProtocolID) {
        switch byteValue {
        case 0x9:
            self = .noteOn(protocolID)
        case 0x8:
            self = .noteOff(protocolID)
        case 0xB:
            self = .controlChange(protocolID)
        case 0xC:
            self = .programChange(protocolID)
        default:
            self = .none
        }
    }
    
}
