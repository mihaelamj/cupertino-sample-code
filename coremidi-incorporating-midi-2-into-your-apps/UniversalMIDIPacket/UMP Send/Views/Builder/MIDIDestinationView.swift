/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lists available MIDI destinations.
*/

import SwiftUI

struct MIDIDestinationView: View {
        
    @ObservedObject var packetModel: PacketModel
    @ObservedObject var endpointManager: MIDIEndpointManager
    
    var body: some View {
        VStack {
            Text("Destination")
                .frame(height: 40.0)
            Spacer()
            Picker(selection: $endpointManager.currentDestinationIndex, label: Text("")) {
                ForEach((0..<endpointManager.midiDestinations.count), id: \.self) {
                    Text(endpointManager.midiDestinations[$0].name).tag($0)
                }
            }
            .frame(width: 270.0)
            .clipped()
            .labelsHidden()
            
            Button(action: {
                packetModel.sendCallback?()
            }) {
                Text("Send")
            }
            Spacer()
        }
    }
}
