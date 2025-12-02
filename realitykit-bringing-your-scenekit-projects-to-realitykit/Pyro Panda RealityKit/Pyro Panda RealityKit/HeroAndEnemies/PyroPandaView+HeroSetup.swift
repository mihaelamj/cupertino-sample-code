/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup for the main hero character in the game.
*/

import RealityKit
import CharacterMovement
import ControllerInput

extension PyroPandaView {
    func heroSetup(_ hero: Entity) async {
        let bounds = hero.visualBounds(relativeTo: hero.parent)
        await hero.components.set(heroComponents(bounds: bounds))

        guard let maxRoot = hero.findEntity(named: "Max"),
              let animationLibrary = maxRoot.components[AnimationLibraryComponent.self]
        else { return }

        var anims = [CharacterStateComponent.CharacterState: AnimationResource]()
        var jumpAnimation = animationLibrary.animations["jump"]
        var endOfJump = jumpAnimation?.definition
        let endOfJumpDuration = endOfJump?.duration ?? 1.0
        endOfJump?.trimStart = endOfJumpDuration - 0.1

        // Create a filler animation after the initial jump animation
        // to hold the jumping position.
        if let jump = jumpAnimation, let endOfJump,
           let endOfJumpAnimation = try? AnimationResource.generate(with: endOfJump),
           let sequenceJump = try? AnimationResource.sequence(with: [jump, endOfJumpAnimation.repeat()]) {
            jumpAnimation = sequenceJump
        }

        anims[.jump] = jumpAnimation?.combineWithAudio(named: "jump")
        anims[.spin] = animationLibrary.animations["spin"]?.combineWithAudio(named: "attack")
        anims[.idle] = animationLibrary.animations["idle"]?.repeat()
        anims[.walking] = animationLibrary.animations["walk"]?.repeat()

        let characterStates = CharacterStateComponent(animations: anims)
        hero.components.set(characterStates)

        // Register the attack actions.
        HeroAttackAction.registerAction()
        HeroAttackActionHandler.register { _ in
            HeroAttackActionHandler()
        }

#if os(visionOS)
        // Set particles to inherit the transform in visionOS.
        hero.findEntity(named: "smoke")?
            .components[ParticleEmitterComponent.self]?.particlesInheritTransform = true
        hero.findEntity(named: "fire")?
            .components[ParticleEmitterComponent.self]?.particlesInheritTransform = true
        hero.findEntity(named: "whiteSmoke")?.components.remove(ParticleEmitterComponent.self)
        hero.parent?.findEntity(named: "enemy_fearful")?
            .components[ParticleEmitterComponent.self]?.particlesInheritTransform = true
#endif // os(visionOS)
    }

    func heroComponents(bounds: BoundingBox) async -> [any Component] {
        let collisionRadius = bounds.extents.x / 2
        let heroCollisionShape: ShapeResource = .generateCapsule(
            height: bounds.extents.y,
            radius: collisionRadius
        ).offsetBy(translation: [0, bounds.center.y, 0])

        var heroPhysicsBody = PhysicsBodyComponent(shapes: [heroCollisionShape], mass: 1, mode: .dynamic)
        heroPhysicsBody.material = PhysicsMaterialResource.generate(friction: 0.3, restitution: 0.0)
        heroPhysicsBody.angularDamping = 1000

        var moveComponent = CharacterMovementComponent(characterProxy: "Max")
        moveComponent.update = self.heroMoveUpdated(entity:velocity:deltaTime:)
        moveComponent.handleKeypress = self.characterKeypress(keypress:)

        return [
            HeroComponent(),
            moveComponent,
            ControllerInputReceiver(update: controllerInputUpdater),
            CollisionComponent(shapes: [.generateCapsule(height: bounds.extents.y, radius: bounds.extents.x / 2)]),
            CharacterControllerComponent(
                radius: bounds.extents.x / 2,
                height: bounds.extents.y,
                collisionFilter: heroCollisionFilter
            )
        ]
    }

    /// Moves the hero character back to the starting point.
    func resetMaxPosition(event: CollisionEvents.Began) {
        var maxParent = event.entityB
        if maxParent.name != "max_parent" {
            maxParent = event.entityA
            if maxParent.name != "max_parent" { return }
        }
        maxParent.teleportCharacter(to: [0, 0.5, -0.25], relativeTo: maxParent.parent)
    }

    /// Stops receiving inputs for the hero character.
    func stopMaxInputs(hero: Entity) {
        if var characterStateComponent = hero.components[CharacterStateComponent.self],
           var characterMovementComponent = hero.components[CharacterMovementComponent.self] {
            hero.stopAllAnimations()
            hero.stopAllAudio()
            characterStateComponent.currentState = .idle
            hero.components.set(characterStateComponent)

            characterMovementComponent.paused = true
            hero.components.set(characterMovementComponent)
        }
    }
}
