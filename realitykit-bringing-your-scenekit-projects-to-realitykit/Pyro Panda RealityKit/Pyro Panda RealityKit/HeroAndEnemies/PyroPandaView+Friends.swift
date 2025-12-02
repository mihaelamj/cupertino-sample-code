/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sets up the captive friends.
*/

import Foundation
import RealityKit
import PyroPanda

extension PyroPandaView {
    func setupCaptiveFriends(_ game: Entity) {
        ["A", "B", "C"].forEach { letter in
            guard let friend = game.findEntity(named: "friend\(letter)"),
               let friendEntity = friend.findEntity(named: "friend"),
               let friendAnimations = friendEntity.components[AnimationLibraryComponent.self],
                  let idleAnimation = friendAnimations.animations["idle"] else { return }

            friendEntity.playAnimation(idleAnimation.repeat())
                .speed = .random(in: 0.75...1.5)
        }
    }

    func spawnFriends(_ scene: Entity, near position: simd_float3) {

        // Find `friendA`, `friendB`, and `friendC` entities and prepare them
        // for running alongside 97 other friends.
        let models: [Entity] = ["A", "B", "C"].compactMap { letter in
            guard var friend = scene.findEntity(named: "friend\(letter)") else { return nil }
            setupFriendEntity(&friend)
            appModel.friends.append(friend)
            return friend
        }

        guard !models.isEmpty else {
            fatalError("Can't spawn friends. Check your scene.")
        }

        // Add clones to the friends collection.
        for i in 0..<AppModel.friendCount - models.count {
            guard var friend = models.randomElement()?.clone(recursive: true)
            else { continue }
            friend.name = "Friend_\(i)"

            // Place your friend.
            let randX = (Float(arc4random()) / Float(UInt32.max)) - 0.5 // Range: -0.5 to 0.5
            let randZ = Float(arc4random()) / Float(UInt32.max)         // Range: 0 to 1

            friend.position = simd_make_float3(
                // Positions between `-0.7` and `0.7`.
                position.x + (randX * 1.4),

                // No change in Y.
                position.y,

                // Moves back between `0` and `2.5` m (back of the prison).
                position.z - (2.5 * randZ)
            )

            // Set up the entity.
            setupFriendEntity(&friend)

            // Add to the list and to the scene.
            appModel.friends.append(friend)
            scene.addChild(friend)
        }
    }

    func setupFriendEntity(_ friend: inout Entity) {
        // Unsynchronize the animation.
        let speed: Float = .random(in: 0.75...1.5)
        if var runAwayComponent = friend.components[RunAwayComponent.self] {
            runAwayComponent.speed = speed
            runAwayComponent.entityRadius = 0.15
            runAwayComponent.curve = 0.4
            friend.components.set(runAwayComponent)
        }
    }

    func animateFriends() {
        appModel.friends.forEach { friend in
            if let friendEntity = friend.findEntity(named: "friend"),
               let friendAnimations = friendEntity.components[AnimationLibraryComponent.self],
               let walkAnimation = friendAnimations.animations["walk"] {

                if var runAwayComponent = friend.components[RunAwayComponent.self] {
                   let friendAnimationController = friendEntity.playAnimation(walkAnimation.repeat())
                    friendAnimationController.speed = runAwayComponent.speed

                    // Make them run.
                    runAwayComponent.isRunning = true
                    friend.components.set(runAwayComponent)
                }
            }
        }
    }
}
