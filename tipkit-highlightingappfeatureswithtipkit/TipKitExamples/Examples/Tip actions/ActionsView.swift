/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that sets up the action button examples.
*/

import SwiftUI

struct ActionsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Password reset") {
                    PasswordResetView()
                }

                NavigationLink("Learn more") {
                    LearnMoreView()
                }
            }
        }
    }
}

#Preview {
    ActionsView()
}
