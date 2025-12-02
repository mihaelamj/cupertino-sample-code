/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the gameplay state.
*/

import RealityKit

/// An enumeration that represents the current game state, and is also a component.
public enum GamePlayStateComponent: Component, Sendable, Equatable {
    
    /// Loading the game assets into memory.
    case loadingAssets
    
    /// Assets are done loading.
    case assetsLoaded
    
    /// Playing an intro animation before gameplay starts.
    case introAnimation
    
    /// Gameplay is starting.
    case starting
    
    /// The player is playing the game, so you can pause the state.
    case playing(isPaused: Bool)
    
    /// Playing the outro animation.
    case outroAnimation
    
    /// Postgame, displaying the high-score view.
    case postGame
    
    var isBeforeGamePlay: Bool {
        switch self {
        case .loadingAssets, .assetsLoaded, .introAnimation, .starting: true
        case .playing, .outroAnimation, .postGame: false
        }
    }
    
    var isPhysicsAllowed: Bool {
        self == .playing(isPaused: false) || self == .outroAnimation
    }
    
    var isMenuDisabled: Bool {
        switch self {
            case .loadingAssets, .introAnimation, .outroAnimation: true
            default: false
        }
    }
    
    var isPlayingGame: Bool {
        switch self {
        case .playing(let isPaused):
            return isPaused == false
        default:
            return false
        }
    }
}
