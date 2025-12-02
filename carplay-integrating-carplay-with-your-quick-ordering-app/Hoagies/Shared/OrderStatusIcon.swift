/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage compact views the system displays in Live Activities.
*/

import SwiftUI

struct OrderStatusIcon: View {
    
    let state: OrderStatusAttributes.ContentState
    
    var body: some View {
        Text("\(state.isReady == true ? "✅" : state.isPreparing == true ? "🧑‍🍳" : state.isConfirmed == true ? "👍" : "❌")")
        .padding()
    }
}
