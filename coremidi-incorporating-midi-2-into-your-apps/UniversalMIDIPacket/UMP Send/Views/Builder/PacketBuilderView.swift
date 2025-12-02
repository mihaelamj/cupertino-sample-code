/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for building MIDI packets.
*/

import SwiftUI

enum ChunkDisplayType {
    case none
    case indexedRaw(String? = nil)
    case indexedNamed([String])
    case slider01
    case numberEntry
    case toggle
}

struct PacketBuilderView: View {
        
    @ObservedObject var packetModel: PacketModel
    @ObservedObject var endpointManager: MIDIEndpointManager
    
    var body: some View {
        HStack(alignment: .center) {
            MIDIStatusTypeView(packetModel: packetModel)
            if packetModel.status != .none {
                Partition()
                DynamicChunkView(packetModel: packetModel)
                Partition()
                MIDIDestinationView(packetModel: packetModel, endpointManager: endpointManager)
            }
        }
        .padding(.horizontal, UIConstants.defaultMargin)
        .frame(height: 350)
    }
    
}

struct PacketSender_Previews: PreviewProvider {
    static var previews: some View {
        PacketBuilderView(packetModel: PacketModel(), endpointManager: MIDIEndpointManager())
    }
}
