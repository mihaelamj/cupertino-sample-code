/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class for interacting with Core MIDI destinations and sources.
*/

import Foundation
import CoreMIDI

class MIDIEndpointManager: Identifiable, ObservableObject {
    
    let id = UUID()
    @Published var midiDestinations = [MIDIEndpointModel]()
    
    var currentDestinationIndex = 0
    var currentDestination: MIDIEndpointRef? {
        if currentDestinationIndex < 0 || currentDestinationIndex >= midiDestinations.count { return nil }
        return midiDestinations[currentDestinationIndex].endpointType
    }
    
    init() {
        populateDestinations()
    }
    
    func populateDestinations() {
        midiDestinations.removeAll()
        
        for index in 0..<MIDIGetNumberOfDestinations() {
            let endpoint = MIDIGetDestination(index)

            var nameProperty: Unmanaged<CFString>?
            var protocolID = Int32()

            if MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &nameProperty) == noErr,
               MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyProtocolID, &protocolID) == noErr,
                let protocolID = MIDIProtocolID(rawValue: protocolID) {
                
                let name = "\(nameProperty!.takeRetainedValue() as String) (\(protocolID.description))"

                let destination = MIDIEndpointModel(endpointType: endpoint, name: name, protocolID: protocolID)
                midiDestinations.append(destination)
            }
        }
    }
    
}
