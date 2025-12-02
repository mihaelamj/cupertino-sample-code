/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration representing MIDI attributes.
*/

import Foundation

enum MIDIAttributes: UInt8, CustomStringConvertible, CaseIterable {
    
    case noAttributeData = 0x00
    case manufacturerSpecific = 0x01
    case profileSpecific = 0x02
    case pitch79 = 0x03

    var description: String {
        switch self {
        case .noAttributeData:
            return "No Data"
        case .manufacturerSpecific:
            return "Manu Specific"
        case .profileSpecific:
          return "Profile Specific"
        case .pitch79:
          return "Pitch 7.9"
        }
    }
    
}
