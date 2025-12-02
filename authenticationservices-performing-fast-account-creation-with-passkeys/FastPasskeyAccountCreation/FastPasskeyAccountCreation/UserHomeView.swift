/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple view showing the login status for the user.
*/

import SwiftUI

struct UserHomeView: View {
    @Environment(AccountState.self) private var accountState

    var body: some View {
        VStack {
            Text("Logged in")

            Button("Sign Out") {
                accountState.isLoggedIn = false
            }
        }
    }
}

#Preview {
    UserHomeView()
}
