/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that sets up the event tips examples.
*/

import SwiftUI

struct EventView: View {
    var body: some View {
        List {
            NavigationLink("Basic Event Tip") {
                EventRuleView()
            }
            
            NavigationLink("Event Tip using custom data type") {
                FoodDetailView()
            }
        }
        .navigationTitle("Event rules")
    }
}

#Preview {
    EventView()
}
