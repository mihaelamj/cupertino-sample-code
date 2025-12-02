/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration representing a chunk in a MIDI packet.
*/

import Foundation
import SwiftUI

enum PacketChunkDescription: String {
    
    case mtNibble       = "MT"
    case group          = "Group"
    case status         = "Status"
    case channel        = "Channel"
    case noteNumber     = "Note Number"
    case attributeType  = "Attribute Type"
    case velocity       = "Velocity"
    case attribute      = "Attribute"
    case index          = "Index"
    case reserved       = "Reserved"
    case data           = "Data"
    case optionsFlags   = "Options Flag"
    case bankValidBit   = "Bank Valid"
    case program        = "Program"
    case bankMSB        = "Bank MSB"
    case bankLSB        = "Bank LSB"

    var color: Color {
        switch self {
        case .mtNibble:
            return (Color.black).opacity(0.3)
            
        case .group:
            return (Color.black).opacity(0.6)
            
        case .status:
            return .gray
            
        case .channel:
            return .blue
            
        case .noteNumber:
            return .green
            
        case .attributeType:
            return .pink
            
        case .velocity:
            return .red
            
        case .attribute:
            return .purple
            
        case .index:
            return .init(Color.RGBColorSpace.sRGB, red: 0.75, green: 0.5, blue: 0.25, opacity: 1.0)
            
        case .reserved:
            return (Color.black).opacity(0.45)
            
        case .data:
            return .init(Color.RGBColorSpace.sRGB, red: 0.75, green: 0.35, blue: 0.35, opacity: 1.0)
            
        case .optionsFlags:
            return .init(Color.RGBColorSpace.sRGB, red: 0.15, green: 0.35, blue: 0.95, opacity: 1.0)
            
        case .bankValidBit:
            return .init(Color.RGBColorSpace.sRGB, red: 0.32, green: 0.05, blue: 0.55, opacity: 1.0)

        case .program:
            return .init(Color.RGBColorSpace.sRGB, red: 0.88, green: 0.05, blue: 0.15, opacity: 1.0)
            
        case .bankMSB:
            return .init(Color.RGBColorSpace.sRGB, red: 0.80, green: 0.09, blue: 0.19, opacity: 1.0)
            
        case .bankLSB:
            return .init(Color.RGBColorSpace.sRGB, red: 0.5876, green: 0.9, blue: 0.3954, opacity: 1.0)
        }
    }
    
}
