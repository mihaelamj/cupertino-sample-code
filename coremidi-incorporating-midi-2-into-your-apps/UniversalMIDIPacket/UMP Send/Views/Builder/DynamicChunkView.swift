/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that can change to dynamically show a packet chunk.
*/

import SwiftUI

struct DynamicChunkView: View {
        
    @ObservedObject var packetModel: PacketModel
    
    var body: some View {
        ForEach(packetModel.chunks) { elementInfo in
            if elementInfo.editable {
                switch elementInfo.uiType {
                case .indexedRaw(let prefix):
                    IndexPanel(elementInfo: elementInfo, prefix: prefix)
                case .indexedNamed(let items):
                    NamedIndexPanel(elementInfo: elementInfo, items: items)
                case .slider01:
                    SliderPanel(elementInfo: elementInfo)
                case .numberEntry:
                    SliderPanel(elementInfo: elementInfo)
                case .toggle:
                    TogglePanel(elementInfo: elementInfo)
                default:
                    EmptyView()
                }
            }
        }
    }
    
}
