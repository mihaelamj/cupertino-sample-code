/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure to help handle keyboard inputs for game controls.
*/

import SwiftUI
import RealityKit

/// A controller for connecting WASD input controls to an app.
///
/// Add this controller's ``handleKeypress(keypress:directionalCallback:additionalKeysCallback:)``
/// method to your SwiftUI keypress handler.
///
/// ```swift
/// HStack {
///     // some content...
/// }.onKeyPress(phases: .all, action: { keypress in
///     WASDController.shared.handleKeypress(
///         keypress: keypress,
///         directionalCallback: <#WASD and arrows callback#>,
///         additionalKeysCallback: <#Additional keys callback#>
///     )
/// })
/// ```
@MainActor
public struct WASDController {
    /// A public shared instance of the WASD controller.
    public static var shared: WASDController = WASDController()
    /// The additional keys that you want to capture from this controller.
    public static var additionalKeys: Set<KeyEquivalent> = [.space, KeyEquivalent("/")]

    /// The modifier that represents any arrow key.
    static let arrowKeyModifiers = EventModifiers(rawValue: 96)
    let disallowedModifiers: EventModifiers = .all.subtracting(Self.arrowKeyModifiers)
    fileprivate func checkDirectionWASD(_ wasdDirection: inout SIMD2<Float>) {
        for wasd in activeStrings {
            let newDirection: SIMD2<Float> = switch wasd {
            case "w": 3 * [0, -1]
            case "a": 3 * [-1, 0]
            case "s": 3 * [0, 1]
            case "d": 3 * [1, 0]
            default: [0, 0]
            }
            wasdDirection += newDirection
        }
    }

    fileprivate func checkDirectionArrows(_ arrowDirection: inout SIMD2<Float>) {
        for keyEquiv in activeKeys {
            let newDirection: SIMD2<Float> = switch keyEquiv {
            case .upArrow: [0, -1]
            case .leftArrow: [-1, 0]
            case .downArrow: [0, 1]
            case .rightArrow: [1, 0]
            default: [0, 0]
            }
            arrowDirection += newDirection
        }
    }

    mutating public func handleKeypress(
        keypress: KeyPress,
        directionalCallback: (_ wasd: SIMD2<Float>, _ arrow: SIMD2<Float>) -> Void,
        additionalKeysCallback: ((_ keypress: KeyPress) -> Void)? = nil
    ) -> KeyPress.Result {
        if keypress.phase == .repeat { return .handled }
        if !keypress.modifiers.contains(disallowedModifiers) || keypress.phase == .up {
            if keypress.phase == .down {
                if !handlePress(keypress) { return .ignored }
            } else {
                if !handleRelease(keypress) { return .ignored }
            }
        }
        var wasdDirection: SIMD2<Float> = [0, 0]
        var arrowDirection: SIMD2<Float> = [0, 0]
        checkDirectionWASD(&wasdDirection)
        checkDirectionArrows(&arrowDirection)

        // Callbacks.
        directionalCallback(wasdDirection, arrowDirection)
        if Self.additionalKeys.contains(keypress.key) {
            additionalKeysCallback?(keypress)
        }

        return .handled
    }

    mutating func handleRelease(_ keypress: KeyPress) -> Bool {
        if activeStrings.contains(keypress.characters) {
            activeStrings.remove(keypress.characters)
        } else if activeKeys.contains(keypress.key) {
            activeKeys.remove(keypress.key)
        } else {
            return false
        }
        return true
    }

    mutating func handlePress(_ keypress: KeyPress) -> Bool {
        if wasdSet.contains(keypress.characters) {
            activeStrings.insert(keypress.characters)
        } else if keySet.contains(keypress.key) {
            activeKeys.insert(keypress.key)
        } else {
            return false
        }
        return true
    }

    var activeStrings = Set<String>()
    var activeKeys = Set<KeyEquivalent>()

    let keySet: Set<KeyEquivalent> = [
        .upArrow, .leftArrow,
        .downArrow, .rightArrow,
        .space, KeyEquivalent("/")
    ]
    let wasdSet: Set<Character> = ["w", "a", "s", "d"]
}
