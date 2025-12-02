/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to simulate an account signing in.
*/

import SwiftUI

struct SignInView: View {

    let keychainController: KeychainController?
    let didSignInHandler: (() -> Void)?

    @Namespace private var credentialsScope
    @State private var username: String = "johnappleseed"
    @State private var password: String = "fake"

    var body: some View {
        HStack {
            VStack {
                Text("Welcome")
                    .font(.title)
                Text("Please sign in to your account")
                    .font(.subheadline)
            }
            .frame(width: 990)

            VStack {
                TextField("Email", text: $username)
                SecureField("Password", text: $password)
                Button("Sign In") {
                    keychainController?.save(username: username, password: password)
                    didSignInHandler?()
                }
                .prefersDefaultFocus(in: credentialsScope)
            }
            .focusScope(credentialsScope)
        }
        .onExitCommand(perform: {
            // Providing an empty closure prevents someone from skipping the sign-in screen by pressing the Menu button.
        })
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(keychainController: nil, didSignInHandler: nil)
    }
}
