/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds the hummingbird and animations, and shows the content in front of the person.
*/

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    /// The root for the follow scene.
    let followRoot: Entity = Entity()
    
    /// The root for the head anchor.
    let headAnchorRoot: Entity = Entity()
    /// The root for the entities in the head-anchored scene.
    let headPositionedEntitiesRoot: Entity = Entity()
    
    /// The root entities for the hummingbird and feeder.
    let hummingbird: Entity = Entity()
    let feeder: Entity = Entity()
    
    var body: some View {
        RealityView { content in
            do {
                // MARK: Load the hummingbird and add the follow scene.
                // Load the hummingbird.
                let hummingbirdContent = try await Entity(named: "Hummingbird", in: realityKitContentBundle)
                hummingbirdContent.scale = SIMD3<Float>(repeating: 0.02)
                hummingbird.addChild(hummingbirdContent)
                
                // Play the animation.
                playHummingbirdAnimation()
                
                // Add the `FollowComponent` to the follow scene so the hummingbird follows the person.
                followRoot.components.set(FollowComponent())
                content.add(followRoot)
                
                // MARK: - Load the feeder and use `AnchorEntity` to position it.
                // Load the feeder.
                let feederContent = try await Entity(named: "Feeder", in: realityKitContentBundle)
                feeder.addChild(feederContent)
                
                // Add the head-anchor root. Later, you add `AnchorEntity` to this.
                content.add(headAnchorRoot)
                
                // Show the hummingbird and feeder using `AnchorEntity`.
                startHeadPositionMode(content: content)
                
            } catch {
                fatalError("No entity to load")
            }
        } update: { content in
            // Switch between head-position and follow cases.
            toggleHeadPositionModeOrFollowMode(content: content)
        }
        .onDisappear {
            if let hummingbirdContent = hummingbird.children.first {
                hummingbird.removeChild(hummingbirdContent)
            }
        }
    }
}

extension ImmersiveView {
    /// Sets up the follow mode by removing the feeder and adding the hummingbird.
    func startFollowMode() {
        // MARK: Clean up the scene.
        // Find the head anchor in the scene and remove it.
        guard let headAnchor = headAnchorRoot.children.first(where: { $0.name == "headAnchor" }) else { return }
        headAnchorRoot.removeChild(headAnchor)
        
        // Remove the feeder from the view.
        feeder.removeFromParent()
        
        // MARK: - Create the "follow" scene.
        // Set the position of the root so that the hummingbird flies in from the center.
        followRoot.setPosition([0, 1, -1], relativeTo: nil)
        
        // Rotate the hummingbird to face over the left shoulder, which faces the person due to the offset.
        let orientation = simd_quatf(angle: .pi * -0.15, axis: [0, 1, 0]) * simd_quatf(angle: .pi * 0.2, axis: [1, 0, 0])
        hummingbird.transform.rotation = orientation
        
        // Set the hummingbird as a subentity of its root, and move it to the top-right corner.
        followRoot.addChild(hummingbird)
        hummingbird.setPosition([0.4, 0.2, -1], relativeTo: followRoot)
    }
    
    /// Sets up the head-position mode by enabling the feeder, creating a head anchor, and adding the hummingbird and feeder.
    func startHeadPositionMode(content: RealityViewContent) {
        // Reset the rotation so it aligns with the feeder.
        hummingbird.transform.rotation = simd_quatf()
        
        // Create an anchor for the head and set the tracking mode to `.once`.
        let headAnchor = AnchorEntity(.head)
        headAnchor.anchoring.trackingMode = .once
        headAnchor.name = "headAnchor"
        // Add the `AnchorEntity` to the scene.
        headAnchorRoot.addChild(headAnchor)
        
        // Add the feeder as a subentity of the root containing the head-positioned entities.
        headPositionedEntitiesRoot.addChild(feeder)
        
        // Add the hummingbird to the root containing the head-positioned entities and set the position to be further away than the feeder.
        headPositionedEntitiesRoot.addChild(hummingbird)
        hummingbird.setPosition([0, 0, -0.15], relativeTo: headPositionedEntitiesRoot)
        
        // Add the head-positioned entities to the anchor, and set the position to be in front of the wearer.
        headAnchor.addChild(headPositionedEntitiesRoot)
        headPositionedEntitiesRoot.setPosition([0, 0, -0.6], relativeTo: headAnchor)
    }
    
    /// Switches between the follow and head-position modes depending on the `HeadTrackState` case.
    func toggleHeadPositionModeOrFollowMode(content: RealityViewContent) {
        switch appModel.headTrackState {
        case .follow:
            startFollowMode()
        case .headPosition:
            startHeadPositionMode(content: content)
        }
    }
    
    /// Plays the flying animation repeatedly.
    func playHummingbirdAnimation() {
        // Play the animation.
        guard let flyAnimation = hummingbird.availableAnimations.first else { return }
        let repeatedAnimation = flyAnimation.repeat(count: .max)
        hummingbird.playAnimation(repeatedAnimation, transitionDuration: 1, startsPaused: false)
    }
}

