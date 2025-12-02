/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model representing a Core MIDI endpoint.
*/

import Foundation
import CoreMIDI

struct MIDIEndpointModel: Identifiable {
    
    let id = UUID()
    
    let endpointType: MIDIEndpointRef
    let name: String
    let protocolID: MIDIProtocolID
    
    var protocolName: String {
        protocolID.description
    }
    
}
