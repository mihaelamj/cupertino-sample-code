/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup for enemies and their components in the game.
*/

import RealityKit
import SwiftUI
import GameplayKit
import AgentComponent
import PyroPanda
import ControllerInput
import HapticUtility

extension PyroPandaView {
    /// Performs the setup of enemies.
    /// - Parameter content: The reality view content.
    func setupEnemies(content: any RealityViewContentProtocol) async throws {
        guard let gameRoot = appModel.gameRoot else { return }
        guard let chasingEnemy = gameRoot.findEntity(named: "enemy_chasing"),
              let fearingEnemy = gameRoot.findEntity(named: "enemy_fearful")
        else { return }

        basicEnemySetup(on: chasingEnemy, content: content)
        basicEnemySetup(on: fearingEnemy, content: content)

        setupWorldAgents(chasing: chasingEnemy, fearing: fearingEnemy)
    }

    func basicEnemySetup(on enemy: Entity, content: any RealityViewContentProtocol) {
        enemy.components.set(AttackComponent())
        enemy.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.enemyFilter
        enemy.components[CollisionComponent.self]?.mode = .trigger

        _ = content.subscribe(to: CollisionEvents.Updated.self, on: enemy, enemyCollisionUpdate(event:))
        _ = content.subscribe(to: CollisionEvents.Began.self, on: enemy, enemyCollisionEnvironment(event:))
    }

    /// Adds agent components to the two enemies in the Pyro Panda game.
    /// - Parameters:
    ///   - chasing: The entity that represents the chasing enemy.
    ///   - fearing: The entity that represents the fearing enemy.
    func setupWorldAgents(chasing: Entity, fearing: Entity) {
        guard let hero else { return }

        hero.components.set(AgentComponent(agentType: .player))

        let wanderPathPoints: [SIMD3<Float>] = [
            [-1, -0.25, 13], [ 1, -0.25, 13],
            [-1, -0.25, 12], [ 1, -0.25, 12],
            [-1, -0.25, 11], [ 1, -0.25, 11],
            [-1, -0.25, 10], [ 1, -0.25, 10]
        ]
        let stayOnPath = GKPath(points: wanderPathPoints, radius: 0.75, cyclical: true)
        let centerGoal = GKGoal(toStayOn: stayOnPath, maxPredictionTime: 1)

        // Set up the chasing enemy agency.
        let chasingType: AgentComponent.AgentType = .chasing(id: hero.id, distance: 3, speed: 3)
        let chasingComponent = AgentComponent(
            agentType: chasingType,
            wanderSpeed: 3, wanderGoal: GKGoal(toWander: 1),
            centerGoal: centerGoal,
            constraints: .position(y: .exact(-0.25))
        )
        chasing.components.set(chasingComponent)

        // Set up the fearing enemy agency.
        let fearingType: AgentComponent.AgentType = .fearing(id: hero.id, distance: 3, speed: 2)
        let fearingComponent = AgentComponent(
            agentType: fearingType,
            wanderSpeed: 3, wanderGoal: GKGoal(toWander: 1),
            centerGoal: centerGoal,
            constraints: .position(y: .exact(-0.25))
        )
        fearing.components.set(fearingComponent)
    }

    /// An update event that RealityKit fires while the enemy is alive and is colliding with the player.
    /// - Parameter event: The collision event.
    private func enemyCollisionUpdate(event: CollisionEvents.Updated) {
        let enemy: Entity = event.entityA
        let hero: Entity = event.entityB

        guard event.entityB.id == self.hero?.id else { return }

        guard let heroComponent = hero.components[HeroComponent.self],
              var attackComponent = enemy.components[AttackComponent.self]
        else { return }

        if heroComponent.isAttacking {
            enemy.components[AgentComponent.self]?.state = .dead
            destroyEnemy(hero: hero, enemy: enemy)
        } else if Date.now.timeIntervalSince1970 - attackComponent.lastAttackTime > attackComponent.attackDelay {
            // The enemy can attack again, so damage the enemy.
            attackComponent.lastAttackTime = Date.now.timeIntervalSince1970
            try? damageCharacter(hero: hero, enemy: enemy)
            enemy.components.set(attackComponent)
        }
    }

    /// Performs an environment collision event that RealityKit fires when the enemy collides with an environment
    /// after it dies.
    /// - Parameter event: The collision event.
    func enemyCollisionEnvironment(event: CollisionEvents.Began) {
        let enemy: Entity = event.entityA
        let environment: Entity = event.entityB

        let floorOrLavaGroup: CollisionGroup = [
            PyroPandaCollisionGroup.environment, PyroPandaCollisionGroup.lava
        ]
        guard enemy.components.has(AttackComponent.self),
              let enemyCollision = environment.components[CollisionComponent.self],
              !enemyCollision.filter.group.isDisjoint(with: floorOrLavaGroup)
        else { return }

        enemy.components.remove(AttackComponent.self)
        let entityParent = enemy.parent
        let entPos = enemy.position
        Task {
            if let particleEntity = try? await Entity(
                named: "Particles/enemy_explosion", in: pyroPandaBundle
            ) {
                particleEntity.position = entPos
                entityParent?.addChild(particleEntity)
                particleEntity.recursiveCall { entity in
                    entity.components[ParticleEmitterComponent.self]?.burst()
                }
            }
        }
        enemy.components.set(OpacityComponent())
        let fadeAction = FromToByAction(to: Float.zero)
        let stayFadedAction = FromToByAction(from: .zero, to: Float.zero)
        let enabledAction = SetEntityEnabledAction(isEnabled: false)
        let hitEnemyAudioAction = PlayAudioAction(audioResourceName: "explosion2")

        guard let fadeAnim = try? AnimationResource.makeActionAnimation(
                for: fadeAction, duration: 0.5, bindTarget: .opacity),
              let stayFadedAnim = try? AnimationResource.makeActionAnimation(
                for: stayFadedAction, duration: 1, bindTarget: .opacity),
              let enabledAnim = try? AnimationResource.makeActionAnimation(for: enabledAction),
              let audioAnimation = try? AnimationResource.makeActionAnimation(for: hitEnemyAudioAction),
              let sequencedAnim = try? AnimationResource.sequence(
                with: [fadeAnim, stayFadedAnim, enabledAnim]),
              let groupedAnim = try? AnimationResource.group(with: [audioAnimation, sequencedAnim])
        else { return }
        enemy.playAnimation(groupedAnim)
    }

    /// Performs the logic for destroying an enemy when it collides with the hero and the hero is attacking.
    /// - Parameters:
    ///   - hero: The hero entity.
    ///   - enemy: The enemy entity.
    func destroyEnemy(hero: Entity, enemy: Entity) {
        guard enemy.components.has(AgentComponent.self),
              let gameRoot = appModel.gameRoot,
              let collision = enemy.components[CollisionComponent.self]
        else { return }

        // Create a dynamic body for the enemy that has high inertia.
        var physicsBody = PhysicsBodyComponent(shapes: collision.shapes, mass: 1, mode: .dynamic)
        physicsBody.angularDamping = 1.0
        physicsBody.linearDamping = 1.5
        var enemyPos = enemy.position(relativeTo: gameRoot)
        var heroPos = hero.position(relativeTo: gameRoot)
        // Flatten positions, to just get x-z offset.
        enemyPos.y = 0
        heroPos.y = 0

        let motionComponent = PhysicsMotionComponent(
            linearVelocity: simd_normalize(enemyPos - heroPos) * 5,
            angularVelocity: [0, 40, 0]
        )
        enemy.components[AgentComponent.self]?.state = .dead

        let hidEnemyAudioAction = PlayAudioAction(audioResourceName: "explosion1")
        if let audioAnimation = try? AnimationResource.makeActionAnimation(for: hidEnemyAudioAction) {
            enemy.playAnimation(audioAnimation)

            // Play boing haptics.
            HapticUtility.playHapticsFile(named: "Boing")
        }

        enemy.components.set([physicsBody, motionComponent])
        enemy.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.enemyDeadFilter
        // This collision filter allows `enemyCollisionEnvironment(_:)` to trigger.
    }

    /// Performs damage to the character.
    func damageCharacter(hero: Entity, enemy: Entity) throws {
        let hitAudioAction = PlayAudioAction(targetEntity: .entityNamed("Max"), audioResourceName: "hit")
        let hitAudioAnimation = try AnimationResource.makeActionAnimation(for: hitAudioAction)
        let opacityLow = try AnimationResource.makeActionAnimation(
            for: FromToByAction(to: Float(0.01)), duration: 0.1, bindTarget: .opacity)
        let opacityHigh = try AnimationResource.makeActionAnimation(
            for: FromToByAction(to: Float(1.0)), duration: 0.1, bindTarget: .opacity)
        let repeatOpacityChange = try AnimationResource.sequence(with: [opacityLow, opacityHigh]).repeat(count: 4)
        // Set the opacity to full at the end to make sure it's back to normal.
        let opacityFull = try AnimationResource.makeActionAnimation(
            for: FromToByAction(to: Float(1.0)), duration: 0, bindTarget: .opacity)

        let animSequence = try AnimationResource.sequence(with: [repeatOpacityChange, opacityFull])
        let animGroup = try AnimationResource.group(with: [hitAudioAnimation, animSequence])
        hero.playAnimation(animGroup)

        // Play damage haptics.
        HapticUtility.playHapticsFile(named: "DamageTaken")
    }
}
