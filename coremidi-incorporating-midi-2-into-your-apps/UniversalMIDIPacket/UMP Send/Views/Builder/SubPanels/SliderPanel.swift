/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows the setting of a value using a slider.
*/

import SwiftUI

struct SliderPanel: View {
    
    @ObservedObject var elementInfo: PacketChunk

    var body: some View {
        VStack {
            Text(elementInfo.name.rawValue)
                .frame(height: 40.0)
            Spacer()
            Slider(value: $elementInfo.floatValue, in: 0.0...1.0)
                .frame(width: 90)
            Spacer()
        }
    }
    
}

struct SliderPanel_Previews: PreviewProvider {
    static var previews: some View {
        SliderPanel(elementInfo: PacketChunk(name: .channel, sizeInBits: 4))
    }
}
