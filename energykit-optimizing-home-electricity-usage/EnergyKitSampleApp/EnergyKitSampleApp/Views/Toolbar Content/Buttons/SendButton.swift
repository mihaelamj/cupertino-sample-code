/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The send button of the app.
*/

import SwiftUI

/// The send button of the app.
struct SendButton: View {
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Label("Send", systemImage: "play")
        }
        .keyboardShortcut("s")
    }
}

#Preview {
    SendButton()
}
