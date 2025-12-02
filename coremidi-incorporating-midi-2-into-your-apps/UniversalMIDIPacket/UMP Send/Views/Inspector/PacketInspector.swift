/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that visualizes a MIDI packet.
*/

import SwiftUI

struct PacketInspector: View {

    @ObservedObject var packetModel: PacketModel
    
    var body: some View {
        HStack {
            ForEach(packetModel.chunks) { item in
                PacketChunkView(item: item)
            }
        }
    }
    
}

struct PacketInspector_Previews: PreviewProvider {
    static var previews: some View {
        PacketInspector(packetModel: PacketModel())
    }
}
