/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays all of the consumable IAP types the app's store class provides.
*/

import Foundation
import StoreKit
import SwiftUI

/// A single view that contains all of the consumable products the store contains.
struct ConsumableProductsView: View {
    @Environment(Store.self) private var store: Store

    var body: some View {
        @Bindable var store = store
        VStack {
            StoreView(ids: ProductID.consumables)
                .storeButton(.hidden, for: .cancellation)
                .storeButton(.visible, for: .restorePurchases)
        }
        .padding()
    }
}

