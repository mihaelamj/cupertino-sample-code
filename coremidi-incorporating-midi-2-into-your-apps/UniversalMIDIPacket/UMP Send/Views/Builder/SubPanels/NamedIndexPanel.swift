/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows selection of an indexed value with text names.
*/

import SwiftUI

struct NamedIndexPanel: View {
    
    @ObservedObject var elementInfo: PacketChunk
    let items: [String]
    
    var body: some View {
        VStack {
            Text(elementInfo.name.rawValue)
                .frame(height: 40.0)
            Spacer()
            Picker(selection: $elementInfo.decimalValue, label: Text("")) {
                ForEach((UInt64(0)..<UInt64(items.count)), id: \.self) {
                    let name = items[Int($0)]
                    Text(name).tag($0)
                }
            }
            .frame(maxWidth: 180.0)
            .clipped()
            .labelsHidden()
            Spacer()
        }
    }
    
}

struct NamedIndexPanel_Previews: PreviewProvider {
    static var previews: some View {
        NamedIndexPanel(elementInfo: PacketChunk(name: .channel, sizeInBits: 4),
                        items: ["One", "Two", "Three", "Four"])
    }
}
