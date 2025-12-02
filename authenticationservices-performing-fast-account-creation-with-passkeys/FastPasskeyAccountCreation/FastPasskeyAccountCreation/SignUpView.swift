/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sign-up view showing the fast account creation flow using passkeys.
*/

import AuthenticationServices
import SwiftUI
import OSLog

struct SignUpView: View {
    @Environment(\.authorizationController) private var authorizationController
    @Environment(AccountState.self) private var accountState

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SignUpView.self)
    )

    var body: some View {
        Button("Sign Up") {
            Task {
                await performSignUpWithPasskey()
            }
        }
    }

    private func performSignUpWithPasskey() async {
        let provider = ASAuthorizationAccountCreationProvider()
        let request = provider.createPlatformPublicKeyCredentialRegistrationRequest(
            acceptedContactIdentifiers: [.email, .phoneNumber],
            shouldRequestName: true,
            relyingPartyIdentifier: "example.com",
            challenge: await fetchChallenge(),
            userID: fetchUserID()
        )

        do {
            let result = try await authorizationController.performRequest(request)
            if case .passkeyAccountCreation(let account) = result {
                // Register the new `account` on the back end.
                accountState.isLoggedIn = true
                Self.logger.debug("\(String(describing: account))")
            }
        } catch ASAuthorizationError.preferSignInWithApple {
            await performSignInWithApple()
        } catch ASAuthorizationError.deviceNotConfiguredForPasskeyCreation, ASAuthorizationError.canceled {
            // Present the sign-up form.
        } catch {
            Self.logger.error("\(error.localizedDescription)")
        }
    }

    private func fetchChallenge() async -> Data {
        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        return Data()
    }

    private func fetchUserID() -> Data {
        // The `userID` is the identifier for the user's account.
        return Data(UUID().uuidString.utf8)
    }

    private func performSignInWithApple() async {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        do {
            let result = try await authorizationController.performRequest(request)

            if case .appleID(let credential) = result {
                // Log in with the `credential`.
                accountState.isLoggedIn = true
                Self.logger.debug("\(credential)")
            }
        } catch {
            Self.logger.error("\(error.localizedDescription)")
        }
    }
}

#Preview {
    SignUpView()
}
