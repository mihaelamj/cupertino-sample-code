/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model containing the root entities and the functions to toggle between following and launching at the head position.
*/

import SwiftUI
import RealityKit
import ARKit

/// Maintains the app-wide state.
@MainActor
@Observable
class AppModel {
    /// Keeps track of whether the toggle is in head-position or follow mode.
    var headTrackState: HeadTrackState = .headPosition
    
    /// Keeps track of whether the immersive space is open.
    var isImmersiveSpaceOpen: Bool = false
    
    /// Track the state of the toggle.
    /// Follow: Uses `queryDeviceAnchor` to follow the device's position.
    /// HeadPosition: Uses `AnchorEntity` to launch at the head position in front of the wearer.
    enum HeadTrackState: String, CaseIterable {
        case follow
        case headPosition = "head-position"
    }
}
