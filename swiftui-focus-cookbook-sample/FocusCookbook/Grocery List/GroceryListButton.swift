/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An button that presents a Grocery List when its action is invoked.
*/

import SwiftUI

struct GroceryListButton: View {
    @Binding var isActive: Bool

    var body: some View {
        Button {
            isActive = true
        } label: {
            Label("Grocery List", systemImage: "checklist")
        }
        .help("Show grocery list")
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    GroceryListButton(isActive: .constant(false))
}
