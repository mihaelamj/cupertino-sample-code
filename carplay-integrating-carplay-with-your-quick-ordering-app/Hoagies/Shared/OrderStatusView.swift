/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage the order status that the system displays in widgets and the Live Activity.
*/

import SwiftUI

struct OrderStatusView: View {
    
    let state: OrderStatusAttributes.ContentState
    
    var body: some View {
        if state.isConfirmed == false {
            Text("No order found")
        } else {
            VStack(alignment: .leading) {
                Text("Confirmed: \(state.isConfirmed == true ? "✅" : "❌")")
                Text("Preparing: \(state.isPreparing == true ? "✅" : "❌")")
                Text("Ready: \(state.isReady == true ? "✅" : "❌")")
            }
            // In an iOS app running on a Mac, the widgets launch Safari if there isn't an app to launch.
            .widgetURL(URL(string: "https://developer.apple.com/documentation/widgetkit"))
            .padding()
        }
    }
}
