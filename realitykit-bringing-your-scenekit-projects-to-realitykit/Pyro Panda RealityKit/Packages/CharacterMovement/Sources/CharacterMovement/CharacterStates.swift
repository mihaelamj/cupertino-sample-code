/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that holds the current state of a RealityKit character.
*/

import Combine
import GameKit
import RealityKit

/// A component that holds the current state of a character.
public struct CharacterStateComponent: Component {
    /// The possible character states for any character using the character state component.
    public enum CharacterState: String, CaseIterable {
        case idle = "idle"
        case walking = "walk"
        case jump = "jump"
        case spin = "spin"

        @MainActor public static var prefix: String = ""
        var filename: String { rawValue }
    }

    @MainActor
    static var bundle: Bundle?

    /// The current character state.
    public var currentState: CharacterState?
    /// The animation resources for each character state.
    var animations: [CharacterState: AnimationResource] = [:]

    /// The possible character states for the character.
    var animationStates: [CharacterState]
    /// The animation controller for the character.
    var animController: AnimationPlaybackController?

    public var isOnFire: Bool = false

    fileprivate static func calculateControllerSpeed(
        for state: CharacterStateComponent.CharacterState, speed movementSpeed: Float
    ) -> Float {
        switch state {
        case .walking: movementSpeed
        case .jump: 2
        case .spin: 2
        default: 1
        }
    }

    @MainActor fileprivate static func changeCurrentState(
        entity: Entity,
        _ currentState: CharacterState?,
        isOnGround: Bool,
        newState: CharacterState,
        isAnimationPlaying: Bool,
        transitionDuration: inout Double
    ) -> Bool {
        switch currentState {
            case .walking where newState == .idle:
            entity.stopAllAudio()
            entity.stopAllAnimations()

            // Set the opacity back to `1.0` in case an enemy hits Max.
            if let opacityFull = try? AnimationResource.makeActionAnimation(
                for: FromToByAction(to: Float(1.0)), duration: 0.1, bindTarget: .opacity) {
                entity.playAnimation(opacityFull, transitionDuration: 0.1)
            }
            case .jump:
                guard newState == .spin || isOnGround || !isAnimationPlaying
                else { return false }
                transitionDuration = 0.1
            case .spin:
                guard !isAnimationPlaying else { return false }
            case .none, .idle, .walking: break
            default:
                let oldState = currentState?.rawValue ?? "nil"
                fatalError("not yet handling \(oldState) to \(newState)")
        }
        return true
    }

    /// Updates the current state of the character component on an entity.
    /// - Parameters:
    ///   - entity: The entity to update the component on.
    ///   - newState: The new character state.
    ///   - movementSpeed: The speed at which the character moves.
    ///   - proxyName: The name of the subentity that holds the character's model for animation.
    ///     If the root entity holds the character, omit this parameter.
    @MainActor
    @discardableResult
    public static func updateState(
        for entity: Entity, to newState: CharacterState,
        movementSpeed: Float, childProxy proxyName: String? = nil
    ) throws -> AnimationPlaybackController? {
        guard var stateComponent = entity.components[CharacterStateComponent.self],
              let controllerState = entity.components[CharacterControllerStateComponent.self]
        else { return nil }
        let playableEntity = if let proxyName, let proxyEntity = entity.findEntity(named: proxyName) {
            proxyEntity
        } else { entity }

        guard let newAnim = stateComponent.animations[newState] else {
            return nil
        }
        if stateComponent.currentState != newState {
            let allowedStates = [CharacterState.idle, .walking, .jump, .spin]
            if !allowedStates.contains(newState) {
                fatalError("Cannot handle \(newState) from nil.")
            }
            var transitionDuration: TimeInterval = 0.3
            guard changeCurrentState(
                entity: entity,
                stateComponent.currentState,
                isOnGround: controllerState.isOnGround,
                newState: newState,
                isAnimationPlaying: stateComponent.animController?.isPlaying ?? false,
                transitionDuration: &transitionDuration
            ) else { return stateComponent.animController }

            stateComponent.animController = playableEntity.playAnimation(
                newAnim, transitionDuration: transitionDuration
            )
            stateComponent.currentState = newState
        }
        // Update the speed of the animations.
        stateComponent.animController?.speed = calculateControllerSpeed(
            for: newState, speed: movementSpeed * (stateComponent.isOnFire ? 2 : 1))
        entity.components.set(stateComponent)
        return stateComponent.animController
    }

    var bundle = Bundle.main
    var prefix: String = ""

    /// Creates a character component with a set of possible character states.
    /// - Parameter animationStates: The animation states to use.
    public init(
        animationStates: [CharacterState] = [.idle, .walking, .jump],
        prefix: String,
        bundle: Bundle = .main
    ) {
        self.animationStates = animationStates
        self.bundle = bundle
        self.prefix = prefix
    }

    /// Performs any necessary setup for the character animations.
    public mutating func loadAnimations() async throws {
        for animationState in animationStates {
            let nextAnim = try await Entity(
                named: self.prefix + animationState.filename,
                in: bundle
            ).availableAnimations.first
            animations[animationState] = nextAnim
        }
    }

    /// Creates a character component with a set of possible character states.
    /// - Parameter animations: The animation states to use.
    public init(animations: [CharacterState: AnimationResource]) {
        animationStates = Array(animations.keys)
        self.animations = animations
    }
}
