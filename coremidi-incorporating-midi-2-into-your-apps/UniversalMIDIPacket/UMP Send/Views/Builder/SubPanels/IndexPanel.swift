/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows the selection of an indexed value.
*/

import SwiftUI

struct IndexPanel: View {
    
    @ObservedObject var elementInfo: PacketChunk
    let prefix: String?
    
    func label(_ index: UInt64) -> String {
        var text = String()
        if let prefix = prefix {
            text += "\(prefix) "
        }
        text += "\(index)"
        return text
    }
    
    var colWidth: CGFloat {
        let font = UIFont.systemFont(ofSize: 12.0)
        let labelWidth = (label(0) as NSString).size(withAttributes: [NSAttributedString.Key.font: font]).width
        
        let headerWidth = (elementInfo.name.rawValue as NSString).size(withAttributes: [NSAttributedString.Key.font: font]).width

        return max(labelWidth, headerWidth) + 4.0
    }
    
    var body: some View {
        VStack {
            Text(elementInfo.name.rawValue)
                .frame(height: 40.0)
            Spacer()
            Picker(selection: $elementInfo.decimalValue, label: EmptyView()) {
                let maxInt = elementInfo.maxDecimalValue
                ForEach((0...maxInt), id: \.self) {
                    Text(label($0)).tag($0)
                }
            }
                .frame(maxWidth: colWidth)
                .clipped()
                .labelsHidden()
            Spacer()
        }
    }
    
}

struct IndexPanel_Previews: PreviewProvider {
    static var previews: some View {
        IndexPanel(elementInfo: PacketChunk(name: .channel, sizeInBits: 4), prefix: nil)
    }
}
