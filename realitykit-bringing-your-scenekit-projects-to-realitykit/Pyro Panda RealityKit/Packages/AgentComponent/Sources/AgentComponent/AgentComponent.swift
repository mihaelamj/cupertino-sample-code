/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that moves a game entity according to agency goals and constraints.
*/

import GameplayKit
import RealityKit
import simd

/// A component that moves a game entity according to a set of goals and realistic constraints
/// in three-dimensional space.
public struct AgentComponent: Component {
    /// The goal types an agent observes.
    public enum AgentType: Equatable {
        /// A behavior that tells an entity to move toward the current position of its target entity.
        case chasing(id: Entity.ID, distance: Float = 5.0, speed: Float = 1.0)
        /// A behavior that tells an entity to move away from the current position of its target entity.
        case fearing(id: Entity.ID, distance: Float = 5.0, speed: Float = 1.0)
        /// A behavior that means external factors, such as a game controller, can affect this player.
        case player
    }
    public let agentType: AgentType?

    /// The possible states for this agent in the scene.
    public enum AgentState: Int {
        case wandering
        case inProximity
        case dead
    }
    /// The current state of this agent.
    public var state: AgentState?

    public enum ConstraintValue {
        case exact(Float? = nil)
        case range(ClosedRange<Float>)
        func clamp(clampingValue: inout Float) {
            clampingValue = switch self {
            case .exact(let value): value ?? clampingValue
            case .range(let range):
                max(range.lowerBound, min(range.upperBound, clampingValue))
            }
        }
    }

    public enum PositionConstraints {
        case position(x: ConstraintValue = .exact(), y: ConstraintValue = .exact(), z: ConstraintValue = .exact())
        case custom((inout SIMD3<Float>) -> Void)

        public func clamp(clampingValue: inout SIMD3<Float>) {
            switch self {
            case .position(let x, let y, let z):
                x.clamp(clampingValue: &clampingValue.x)
                y.clamp(clampingValue: &clampingValue.y)
                z.clamp(clampingValue: &clampingValue.z)
            case .custom(let clampingMethod): clampingMethod(&clampingValue)
            }
        }
    }

    public var positionConstraints: PositionConstraints?

    public typealias GoalWeights = (wander: Float, proximity: Float, center: Float)
    public var stateWeights: [AgentState: GoalWeights] = [:]

    var currentWeights: GoalWeights {
        if let state, let weights = stateWeights[state] {
            return weights
        }
        return switch self.state {
        case .wandering: (wander: 0.2, proximity: 0.0, center: 1.0)
        case .inProximity: (wander: 0.0, proximity: 1.0, center: 0.5)
        case .dead, .none:  (wander: 0.0, proximity: 0.0, center: 0.0)
        }
    }

    /// The GameplayKit agent that this agent controls, which represents the entity's transform.
    public internal(set) var agent: GKAgent3D? {
        didSet {
            agent?.behavior = self.behavior
        }
    }
    public internal(set) var lastUpdate: (positionDelta: SIMD3<Float>, deltaTime: TimeInterval)?

    internal var wanderSpeed: Float = 5.0

    internal var proximityGoal: GKGoal?

    internal var behavior: GKBehavior? {
        didSet { self.agent?.behavior = behavior }
    }

    public internal(set) var wanderGoal: GKGoal?
    public var centerGoal: GKGoal? {
        willSet {
            var weight: Float?
            if let centerGoal {
                weight = self.agent?.behavior?.weight(for: centerGoal)
                self.agent?.behavior?.remove(centerGoal)
            }
            if let newValue {
                self.agent?.behavior?.setWeight(weight ?? 1.0, for: newValue)
            }
        }
    }

    public var isDead: Bool { state == .dead }

    public init(
        agentType: AgentType = .player,
        wanderSpeed: Float = 1.0,
        wanderGoal: GKGoal? = nil,
        centerGoal: GKGoal? = nil,
        constraints: PositionConstraints? = nil
    ) {
        Task { await AgentSystem.registerSystem() }
        self.agentType = agentType
        self.wanderSpeed = wanderSpeed
        self.wanderGoal = wanderGoal
        self.centerGoal = centerGoal
        self.positionConstraints = constraints
        self.behavior = GKBehavior(goals: [wanderGoal, centerGoal].compactMap({ $0 }))
    }
}
