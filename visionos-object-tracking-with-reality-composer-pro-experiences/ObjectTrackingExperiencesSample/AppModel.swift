/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Maintains app-wide state.
*/
import SwiftUI

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
