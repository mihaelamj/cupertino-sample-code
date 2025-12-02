/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view for the user to sign up using the associated domain
  that the developer sets.
*/

import SwiftUI

struct ContentView: View {
    @State var accountState = AccountState()

    var body: some View {
        Group {
            if accountState.isLoggedIn {
                UserHomeView()
            } else {
                SignUpView()
            }
        }
        .environment(accountState)
    }
}

#Preview {
    ContentView()
}
