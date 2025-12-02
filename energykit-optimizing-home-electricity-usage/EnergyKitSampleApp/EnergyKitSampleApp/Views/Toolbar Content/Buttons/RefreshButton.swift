/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The refresh button of the app.
*/

import SwiftUI

/// The refresh button of the app.
struct RefreshButton: View {
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r")
    }
}

#Preview {
    RefreshButton()
}
