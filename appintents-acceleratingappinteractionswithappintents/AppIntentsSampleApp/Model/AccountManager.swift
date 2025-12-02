/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages the app's account state.
*/

import Foundation
import Observation
import SwiftUI

@Observable class AccountManager: @unchecked Sendable {
    
    static let shared = AccountManager()
    
    private static let loggedInKey = "loggedIn"
    
    private init() {
        
    }
    
    var loggedIn: Bool {
        get {
            access(keyPath: \.loggedIn)
            return UserDefaults.standard.bool(forKey: AccountManager.loggedInKey)
        }
        set {
            withMutation(keyPath: \.loggedIn) {
                UserDefaults.standard.setValue(newValue, forKey: AccountManager.loggedInKey)
            }
        }
    }
}
