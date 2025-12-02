/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system that moves entities that have agent goals and constraints.
*/

import GameplayKit
import RealityKit

@MainActor
public struct AgentSystem: System {
    static let query = EntityQuery(where: .has(AgentComponent.self))
    static public var agentsPaused = false

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        entities.forEach { update($0, context: context) }
    }
    func update(_ entity: Entity, context: SceneUpdateContext) {
        guard var agentComponent = entity.components[AgentComponent.self] else { return }
        guard !Self.agentsPaused else { return }

        guard agentComponent.state != .dead else { return }

        if agentComponent.agent == nil {
            let agent = GKAgent3D()
            // RealityKit is left-handed.
            agent.rightHanded = false
            agent.position = entity.position
            agentComponent.agent = agent
        }
        guard var agent = agentComponent.agent else { return }
        guard agentComponent.agentType != .player else {
            agent.position = entity.position
            entity.components.set(agentComponent)
            return
        }

        self.updateAgentState(&agentComponent, entity: entity, context: context)
        agentComponent.agent?.update(deltaTime: context.deltaTime)

        if let positionConstraints = agentComponent.positionConstraints {
            constrainPosition(agent: &agent, constraint: positionConstraints)
        }

        let newOrientation = simd_quatf(from: [0, 0, -1], to: simd_normalize(agent.position - entity.position))
        if !newOrientation.axis.x.isNaN {
            entity.orientation = simd_slerp(entity.orientation, newOrientation, 0.05)
        }

        let positionDiff = agent.position - entity.position
        entity.position = agent.position
        agentComponent.lastUpdate = (positionDiff, context.deltaTime)
        entity.components.set(agentComponent)
    }

    func constrainPosition(agent: inout some GKAgent, constraint: AgentComponent.PositionConstraints) {
        guard let agent = agent as? GKAgent3D else { return }

        var position = agent.position
        constraint.clamp(clampingValue: &position)

        agent.position = position
    }

    func updateAgentState(_ agentComponent: inout AgentComponent, entity: Entity, context: SceneUpdateContext) {
        if agentComponent.state == .none, agentComponent.agentType != .player {
            self.startWandering(&agentComponent)
        }
        guard let agent = agentComponent.agent else { return }
        switch agentComponent.agentType {
        case .chasing(let chaseId, let chaseDistance, let chaseSpeed):
            guard let chaseEntity = context.scene.findEntity(id: chaseId),
               let chaseAgent = chaseEntity.agent
            else { return }
            self.chasingUpdate(
                agent: agent, agentComponent: &agentComponent,
                chaseAgent: chaseAgent, chaseDistance: chaseDistance, chaseSpeed: chaseSpeed
            )
        case .fearing(let fleeId, let fleeDistance, let fleeSpeed):
            guard let fleeingFromEntity = context.scene.findEntity(id: fleeId),
                  let fleeingFromAgent = fleeingFromEntity.agent
            else { return }

            self.fearingUpdate(
                agent: agent,
                agentComponent: &agentComponent,
                fleeingFromAgent: fleeingFromAgent,
                fleeDistance: fleeDistance,
                fleeSpeed: fleeSpeed
            )
        case .player:
            agent.position = entity.position
        case .none:
            if agentComponent.state == .none {
                startWandering(&agentComponent)
            }
        }
    }

    func fearingUpdate(
        agent: GKAgent3D, agentComponent: inout AgentComponent,
        fleeingFromAgent: GKAgent3D, fleeDistance: Float, fleeSpeed: Float
    ) {
        let distanceFrom = simd_distance(fleeingFromAgent.position, agent.position)

        if agentComponent.state == .none {
            startWandering(&agentComponent)
        }
        switch agentComponent.state {
        case .inProximity, .none:
            if distanceFrom > fleeDistance {
                startWandering(&agentComponent)
            }
        case .wandering:
            if distanceFrom < fleeDistance {
                if agentComponent.proximityGoal == nil {
                    agentComponent.proximityGoal = GKGoal(toFleeAgent: fleeingFromAgent)
                }
                startProximityBehavior(&agentComponent, speed: fleeSpeed)
            }
        default: break
        }

    }

    func chasingUpdate(
        agent: GKAgent3D, agentComponent: inout AgentComponent,
        chaseAgent: GKAgent3D, chaseDistance: Float, chaseSpeed: Float
    ) {
        let distance = simd_distance(chaseAgent.position, agent.position)

        if agentComponent.state == .none {
            startWandering(&agentComponent)
        }
        switch agentComponent.state {
        case .inProximity, .none:
            if distance > chaseDistance {
                startWandering(&agentComponent)
            }
        case .wandering:
            if distance < chaseDistance {
                if agentComponent.proximityGoal == nil {
                    agentComponent.proximityGoal = GKGoal(toSeekAgent: chaseAgent)
                }
                startProximityBehavior(&agentComponent, speed: chaseSpeed)
            }
        default: break
        }

    }

    func updateWeights(_ agentComponent: inout AgentComponent, speed: Float? = nil) {
        guard let behavior = agentComponent.behavior else { return }

        let weights = agentComponent.currentWeights

        if let wanderGoal = agentComponent.wanderGoal {
            behavior.setWeight(weights.wander, for: wanderGoal)
        }
        if let proximityGoal = agentComponent.proximityGoal {
            behavior.setWeight(weights.proximity, for: proximityGoal)
        }
        if let centerGoal = agentComponent.centerGoal {
            behavior.setWeight(weights.center, for: centerGoal)
        }
        agentComponent.behavior = behavior
    }

    func startWandering(_ agentComponent: inout AgentComponent) {
        agentComponent.state = .wandering
        updateWeights(&agentComponent)
    }

    func startProximityBehavior(_ agentComponent: inout AgentComponent, speed: Float) {
        agentComponent.state = .inProximity
        updateWeights(&agentComponent, speed: speed)
    }
}

fileprivate extension Entity {
    var agent: GKAgent3D? { components[AgentComponent.self]?.agent }
}
