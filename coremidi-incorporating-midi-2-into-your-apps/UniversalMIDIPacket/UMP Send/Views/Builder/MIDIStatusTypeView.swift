/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lists MIDI status types.
*/

import SwiftUI

struct MIDIStatusTypeView: View {
        
    @ObservedObject var packetModel: PacketModel
    
    var body: some View {
        VStack {
            Text("Message Type")
                .frame(height: 40.0)
            Spacer()
            Picker(selection: $packetModel.statusIndex, label: Text("")) {
                ForEach(0..<MIDIMessageStatus.allCases.count, id: \.self) { index in
                    let item = MIDIMessageStatus.allCases[index]
                    Text(item.description).tag(index)
                }
            }
                .frame(width: 250.0)
                .clipped()
                .labelsHidden()
            Spacer()
        }
    }
    
}

