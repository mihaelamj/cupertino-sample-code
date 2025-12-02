/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents a push pin that pins items onto the card of the display board.
*/

import SwiftUI

struct PinView: View {
    var radius: Double = 15
    
    var body: some View {
        let pinShape = Circle()
        
        pinShape
            .inset(by: 2)
            .background(
                .black.shadow(.drop(
                    color: .black.opacity(0.3),
                    radius: 2,
                    x: 0.3 * radius,
                    y: 0.2 * radius)),
                in: pinShape)
            .frame(width: 2 * radius, height: 2 * radius)
    }
}

#Preview {
    PinView()
}
