/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the connection and tracking status of the DockKit accessory.
*/

import SwiftUI

struct ConnectionView: View {
    var connected: Bool
    var tracking: Bool
    
    var body: some View {
        Image(systemName: "viewfinder")
            .resizable()
            .scaledToFit()
            .foregroundColor(connected ? .green : .white)
            .background(
                tracking ?
                Image(systemName: "face.smiling")
                    .foregroundColor(.white) :
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            )
            .frame(width: 30)
    }
}

#Preview {
    //ConnectionView(connected: true, tracking: false)
}
