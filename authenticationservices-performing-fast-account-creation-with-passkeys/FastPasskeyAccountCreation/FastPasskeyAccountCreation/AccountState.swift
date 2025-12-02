/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable data model with a Boolean property for the account login status.
*/

import SwiftUI

@Observable
class AccountState {
    var isLoggedIn = false
}
