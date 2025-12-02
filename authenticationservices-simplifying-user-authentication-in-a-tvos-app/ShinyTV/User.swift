/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A value that represents an authenticated user
*/

import SwiftUI

/// A value that represents an authenticated user.
struct User: Hashable {
    /// The user's email address.
    let email: String
}

private enum UserKey: EnvironmentKey {
    static let defaultValue = User(email: "user@example.com")
}

extension EnvironmentValues {
    var user: User {
        get { self[UserKey.self] }
        set { self[UserKey.self] = newValue }
    }
}
