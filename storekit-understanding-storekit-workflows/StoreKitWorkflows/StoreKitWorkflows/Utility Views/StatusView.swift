/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility view the app uses to show information about purchased items.
*/

import SwiftUI

struct StatusView: View {
    @Environment(Store.self) private var store: Store
    @Binding var purchased: Bool
    @Binding var consumableCount: Int
    @Binding var subscription: String?

    var body: some View {
        @Bindable var store = store
        
        HStack(alignment: .center, spacing: Constants.statusItemSpacing) {
            Text("Status: ")
                .font(.caption)
            
            // Consumables
            Text("\(consumableCount) consumables")
                .font(.caption)
            
            // Non-consumables
            Text("Non-consumable \(purchased ? "owned" : "not owned")")
                .font(.caption)

            // Subscription
            Text("Subscription: \(subscription ?? "None")")
                .font(.caption)
            
        }
    }
}

#Preview {
    @Previewable @State var counter = 3
    @Previewable @State var nonconsumable = false
    @Previewable @State var subscription: String? = "subscription_yearly"

    StatusView(purchased: $nonconsumable, consumableCount: $counter, subscription: $subscription)
}
