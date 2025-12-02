/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button that initiates the refresh action in the environment.
*/

import SwiftUI

/// A button that initiates the refresh action in the environment.
///
/// This button relies on the refresh action, which you can put into the
/// environment by adding a refreshable modifier to the view hieararchy.
struct RefreshButton: View {
    @Environment (\.refresh) private var refresh

    var body: some View {
        Button {
            Task {
                await refresh?()
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}

#Preview {
    RefreshButton()
}
