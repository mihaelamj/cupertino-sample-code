/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The settings that maintain the app's state.
*/

import SwiftUI
import RealityKit

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

    static let friendCount = 50

    var gameRoot: Entity?
    var gameAudioRoot: Entity? {
        gameRoot?.children.first(where: { $0.name == "Root" })
    }
    var displayOverlaysVisible = false
    var collectedCoin = false
    var collectedKey = false
    let isPortrait = true
    var levelFinished = false
    var friends = [Entity]()

    var metalDevice: MTLDevice? = {
        MTLCreateSystemDefaultDevice()
    }()

    func reset() {
        gameRoot?.removeFromParent()
        gameRoot = nil
        displayOverlaysVisible = false
        collectedCoin = false
        collectedKey = false
        levelFinished = false
        friends = []
    }
}
