/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension for a MIDI event packet that provides conversion functions.
*/

import Foundation
import CoreMIDI

extension MIDICVStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        // MIDI 1.0
        case .noteOff:
            return "Note Off"
        case .noteOn:
            return "Note On"
        case .polyPressure:
            return "Poly Pressure"
        case .controlChange:
            return "Control Change"
        case .programChange:
            return "Program Change"
        case .channelPressure:
            return "Channel Pressure"
        case .pitchBend:
            return "Pitch Bend"
        // MIDI 2.0
        case .registeredPNC:
            return "Registered PNC"
        case .assignablePNC:
            return "Assignable PNC"
        case .registeredControl:
            return "Registered Control"
        case .assignableControl:
            return "Assignable Control"
        case .relRegisteredControl:
            return "Rel Registered Control"
        case .relAssignableControl:
            return "Rel Assignable Control"
        case .perNotePitchBend:
            return "Per Note PitchBend"
        case .perNoteMgmt:
            return "Per Note Mgmt"
        default:
            return ""
        }
    }
}

extension MIDIEventPacket: CustomStringConvertible {
    
    var messageType: MIDIMessageType? {
        // Shift the message by 28 bits to get the message type nibble.
        MIDIMessageType(rawValue: words.0 >> 28)
    }
    
    var hexString: String {
        var data = Data()

        let mirror = Mirror(reflecting: words)
        let elements = mirror.children.map { $0.value }

        for (index, element) in elements.enumerated() {
            guard index < wordCount, let value = element as? UInt32 else { continue }
            
            withUnsafeBytes(of: UInt32(bigEndian: value)) {
                data.append(contentsOf: $0)
            }
        }

        return data.hexString()
    }
    
    var status: MIDICVStatus? {
        /*
        To get only the status nibble, shift by 20 bits (the start position of the status)
         and then perform an AND operation to clear the message type and group nibbles.
        */
        return MIDICVStatus(rawValue: (words.0 >> 20) & 0x00f)
    }
    
    public var description: String {
        guard let messageType = messageType,
              let status = status else {
            return ""
        }
        
        switch messageType {
        case (.utility):
            return "Utility"
        case (.system):
            return "System"
        case (.channelVoice1):
            return "MIDI 1.0 Channel Voice Message (\(status.description))"
        case (.sysEx):
            return "Sysex"
        case (.channelVoice2):
            return "MIDI 2.0 Channel Voice Message (\(status.description))"
        default:
            return ""
        }
    }
}
