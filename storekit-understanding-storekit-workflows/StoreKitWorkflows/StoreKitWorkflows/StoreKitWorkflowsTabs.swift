/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for the app.
*/

import Foundation
import SwiftUI

struct StoreKitWorkflowsExampleTabs: View {
    @Environment(Store.self) private var store: Store
    @State private var selectedTab: Tabs = .allInOne
        
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                
                /// A consolidated, all-in-one view of all products.
                Tab(Tabs.allInOne.name, systemImage: "storefront", value: .allInOne) {
                    AllProductsView()
                }
                /// A view that presents the option to purchase of a single consumable item.
                Tab(Tabs.consumable.name, systemImage: "storefront", value: .consumable) {
                    ConsumableProductsView()
                }
                
                /// A view that presents the option to purchase a single non-consumable item
                Tab(Tabs.nonconsumable.name, systemImage: "storefront", value: .nonconsumable) {
                    NonConsumableProductView()
                }
                /// A view that presents the option to purchase  one or more subscription items.
                Tab(Tabs.allSubscriptions.name, systemImage: "storefront", value: .allSubscriptions) {
                    AllSubscriptionProductsView()
                }

            }
            #if os(macOS)
            .tabViewStyle(.sidebarAdaptable)
            #endif
        }
    }
    
}
