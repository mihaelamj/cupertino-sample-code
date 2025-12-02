/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The add button of the app.
*/

import SwiftUI

/// The add button of the app.
struct AddButton: View {
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Label("Add", systemImage: "plus")
        }
        .keyboardShortcut("a")
    }
}

#Preview {
    AddButton()
}
