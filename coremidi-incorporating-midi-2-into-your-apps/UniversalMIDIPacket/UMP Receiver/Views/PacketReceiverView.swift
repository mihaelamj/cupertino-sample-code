/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MIDI input/output app's receiver view.
*/

import SwiftUI

struct PacketReceiverView: View {
    
    @ObservedObject var receiverOptions: ReceiverOptions
    @ObservedObject var logModel: LogModel
    
    var body: some View {
        VStack {
            Text("Universal MIDI Packet Receiver")
                .font(.title)
                .padding([.vertical, .horizontal], UIConstants.defaultMargin)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            VStack {
                DestinationTextView(receiverOptions: receiverOptions)
                .padding(.vertical, UIConstants.defaultMargin)
                
                DestinationProtocolView(receiverOptions: receiverOptions)
                
                Button(action: {
                    receiverOptions.createMIDIDestination?()
                }) {
                    HStack {
                        Spacer()
                        Text("Create Destination")
                        Spacer()
                    }
                }
                .padding(.vertical, UIConstants.defaultMargin / 2.0)
                Text("Log")
                
                LogView(logModel: logModel)
                    .padding(.horizontal, UIConstants.defaultMargin)
                
            }
        }
//        .frame(minWidth: 800, minHeight: 600)
    }
    
}

struct DestinationTextView: View {
    
    @ObservedObject var receiverOptions: ReceiverOptions
    
    var body: some View {
        VStack {
            Text("Custom Destination Name")
            TextField("", text: $receiverOptions.destinationName)
            .multilineTextAlignment(.center)
            .frame(width: 300)
            .padding()
            .background(UIConstants.backgroundColor)
            .cornerRadius(UIConstants.defaultCornerRadius)
        }
    }
    
}

struct DestinationProtocolView: View {
    
    @ObservedObject var receiverOptions: ReceiverOptions
    
    var body: some View {
        VStack {
            Text("Destination Protocol")
            Picker(selection: $receiverOptions.protocolID, label: Text("")) {
                ForEach((MIDIProtocolID._1_0.rawValue...MIDIProtocolID._2_0.rawValue), id: \.self) {
                    if let midiProtocol = MIDIProtocolID(rawValue: $0) {
                        Text("MIDI \(midiProtocol.description)").tag($0)
                    }
                }
            }
            .clipped()
            .labelsHidden()
            Spacer()
        }
    }
    
}

struct PacketReceiverView_Previews: PreviewProvider {
    static var previews: some View {
        PacketReceiverView(receiverOptions: ReceiverOptions(), logModel: LogModel())
    }
}
