/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MIDI input/output app's sender view.
*/

import SwiftUI

struct PacketSenderView: View {
    
    @ObservedObject var packetModel: PacketModel
    @ObservedObject var logModel: LogModel
    @ObservedObject var endpointManager: MIDIEndpointManager
    
    var body: some View {
        VStack {
            Text("Universal MIDI Packet Send")
                .font(.title)
                .padding(.vertical, UIConstants.defaultMargin)
            Text("Packet Builder")
                .padding(.vertical, UIConstants.defaultMargin)
            
            // Packet Builder View
            PacketBuilderView(packetModel: packetModel, endpointManager: endpointManager)
                .frame(maxHeight: 450)
                .padding(.vertical, UIConstants.defaultMargin)
                .background(UIConstants.backgroundColor)
                .cornerRadius(UIConstants.defaultCornerRadius)
            
            if packetModel.status != MIDIMessageStatus.none {
                Text("Packet Inspector")
                    .padding(.vertical, UIConstants.defaultMargin)
                PacketInspector(packetModel: packetModel)
                    .padding([.vertical, .horizontal], UIConstants.defaultMargin)
                    .background(UIConstants.backgroundColor)
                    .cornerRadius(UIConstants.defaultCornerRadius)
                Button(action: {
                    packetModel.copyHexToClipboard()
                }) {
                    Text("Copy Hex")
                }
            }
            Spacer()
        }
		.frame(minWidth: 1024, minHeight: 800)
    }
    
}

struct PacketSenderView_Previews: PreviewProvider {
    static var previews: some View {
        PacketSenderView(packetModel: PacketModel(),
                         logModel: LogModel(),
                         endpointManager: MIDIEndpointManager())
    }
}
