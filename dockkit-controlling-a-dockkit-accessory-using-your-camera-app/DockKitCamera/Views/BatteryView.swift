/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the current battery status of the connected DockKit accessory.
*/

import SwiftUI

/// A view that displays the current battery status of the connected DockKit accessory.
struct BatteryView: View {
    let fill: Color
    let outline: Color
    var percentage: Double
    var charging: Bool
    var available: Bool
    
    var body: some View {
        ZStack {
            if available {
                Image(systemName: "battery.0")
                    .resizable()
                    .scaledToFit()
                    .font(.headline.weight(.ultraLight))
                    .foregroundColor(outline)
                    .background(
                        Rectangle()
                            .fill(fill)
                            .scaleEffect(x: percentage, y: 1, anchor: .leading)
                    )
                    .mask(
                        Image(systemName: "battery.100")
                            .resizable()
                            .scaledToFit()
                            .font(.headline.weight(.ultraLight))
                    )
            } else {
                Image(systemName: "battery.0")
                    .resizable()
                    .scaledToFit()
                    .font(.headline.weight(.ultraLight))
                    .foregroundColor(outline)
                    .background(
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                    )
            }
            Image(systemName: "bolt.fill")
                .font(.headline.weight(.ultraLight))
                .hidden(charging == false)
        }
        .frame(width: 30)
    }
    
}

#Preview {
    BatteryView(fill: .green, outline: .black, percentage: 0.5, charging: false, available: true)
}
