/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model of the app.
*/

import SwiftUI

public enum ImmersiveSpaceState {
    case closed
    case inTransition
    case open
}

/// Maintains the app-wide state.
@Observable
public class AppModel {
    public var immersiveSpaceState = ImmersiveSpaceState.closed
}
