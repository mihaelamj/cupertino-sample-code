/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for maintaining the app-wide state.
*/

import SwiftUI

/// Maintains the app-wide state.
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
