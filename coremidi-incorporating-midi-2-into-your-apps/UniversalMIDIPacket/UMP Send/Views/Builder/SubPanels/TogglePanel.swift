/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows the setting of a Boolean value using a switch.
*/

import SwiftUI

struct TogglePanel: View {
    
    @ObservedObject var elementInfo: PacketChunk

    var body: some View {
        VStack {
            Text(elementInfo.name.rawValue)
                .frame(height: 40.0)
            Spacer()
            Toggle("", isOn: $elementInfo.boolValue)
                .labelsHidden()
            Spacer()
        }
    }
    
}

struct TogglePanel_Previews: PreviewProvider {
    static var previews: some View {
        TogglePanel(elementInfo: PacketChunk(name: .channel, sizeInBits: 4))
    }
}
