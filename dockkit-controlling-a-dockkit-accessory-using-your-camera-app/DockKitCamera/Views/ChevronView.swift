/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the chevrons for controlling the DockKit accessory.
*/

import SwiftUI

struct ChevronView: View {
    @State var type: ChevronType
    
    var body: some View {
        Button {
            
        } label: {
            getChevron()
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .opacity(0.75)
        }
        .foregroundColor(.white)
    }
    
    private func getChevron() -> Image {
        switch type {
        case .tiltUp:
            return Image(systemName: "chevron.up.circle.fill")
        case .tiltDown:
            return Image(systemName: "chevron.down.circle.fill")
        case .panLeft:
            return Image(systemName: "chevron.left.circle.fill")
        case .panRight:
            return Image(systemName: "chevron.right.circle.fill")
        }
    }
}

#Preview {
    ChevronView(type: ChevronType.tiltUp)
}
