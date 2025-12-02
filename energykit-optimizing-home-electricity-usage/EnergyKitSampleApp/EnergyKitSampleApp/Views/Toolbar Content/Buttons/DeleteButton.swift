/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delete button of the app.
*/

import SwiftUI

/// The delete button of the app.
struct DeleteButton: View {
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Label("Delete", systemImage: "trash")
        }
        .keyboardShortcut("d")
    }
}

#Preview {
    DeleteButton()
}
