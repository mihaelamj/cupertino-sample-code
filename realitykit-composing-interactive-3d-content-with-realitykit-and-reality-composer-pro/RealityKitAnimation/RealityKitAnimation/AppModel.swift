/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model for the app state.
*/

import SwiftUI

public enum ImmersiveSpaceState {
    case closed
    case inTransition
    case open
}

// Maintains an app-wide state.
@Observable
public class AppModel {
    public var immersiveSpaceState = ImmersiveSpaceState.closed
}
