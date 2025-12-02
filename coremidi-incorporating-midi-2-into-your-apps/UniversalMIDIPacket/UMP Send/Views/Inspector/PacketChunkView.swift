/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that visualizes a chunk (segment) of a MIDI packet.
*/

import Foundation
import SwiftUI

struct PacketChunkCell: View {
    
    let title: String
    let width: CGFloat
    let color: Color
    var opacity = 1.0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(opacity))
                .frame(width: width, height: UIConstants.cellSize)
            Text(title)
                .font(.system(size: 12))
        }
    }
    
}

struct PacketChunkView: View {
    
    @ObservedObject var item: PacketChunk

    var headerLabel: String {
        "\(item.sizeLabel) (\(item.rangeLabel))"
    }
    
    var colWidth: CGFloat {
        let font = UIFont.systemFont(ofSize: 12.0)
        let bitSize = item.range.upperBound - item.range.lowerBound
        let maxBinaryLabel = String(repeating: "0", count: bitSize)
        let binaryTextWidth = (maxBinaryLabel as NSString).size(withAttributes: [NSAttributedString.Key.font: font]).width
        
        let headerWidth = (headerLabel as NSString).size(withAttributes: [NSAttributedString.Key.font: font]).width

        return max(binaryTextWidth, headerWidth) + 4.0
    }
    
    var body: some View {
        VStack {
            let color = item.name.color

            Text(headerLabel)
                .font(.system(size: 12))
            PacketChunkCell(title: item.name.rawValue, width: colWidth, color: color)
            PacketChunkCell(title: "\(item.decimalValue)", width: colWidth, color: color, opacity: 0.2)
            PacketChunkCell(title: item.binary, width: colWidth, color: color, opacity: 0.2)
            PacketChunkCell(title: item.hexString, width: colWidth, color: color, opacity: 0.2)
        }
    }
    
}

struct PacketChunkView_Previews: PreviewProvider {
    static var previews: some View {
        PacketChunkView(item: PacketChunk(name: PacketChunkDescription.status, sizeInBits: 8))
    }
}
