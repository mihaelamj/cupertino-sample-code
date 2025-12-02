/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for the app.
*/

import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(Store.self) private var store: Store

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .center, spacing: Constants.verticalViewSpacing) {
            StatusView(purchased: $store.boughtNonConsumable, consumableCount: $store.consumableCount, subscription: $store.activeSubscription)

            StoreKitWorkflowsExampleTabs()
        }
        .padding()
    }
}
