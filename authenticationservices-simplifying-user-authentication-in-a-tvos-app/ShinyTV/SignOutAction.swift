/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An action that allows the user to sign out of the application.
*/

import SwiftUI

/// An action that allows the user to sign out of the application.
struct SignOutAction {
    var user: Binding<User?>

    func callAsFunction() {
        user.wrappedValue = nil
    }
}

private enum SignOutActionKey: EnvironmentKey {
    static let defaultValue = SignOutAction(user: .constant(nil))
}

extension EnvironmentValues {
    var signOut: SignOutAction {
        get { self[SignOutActionKey.self] }
        set { self[SignOutActionKey.self] = newValue }
    }
}
