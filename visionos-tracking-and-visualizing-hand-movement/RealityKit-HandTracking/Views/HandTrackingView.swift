/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure with the entity view protocol to generate and update meshes for each hand anchor.
*/

import SwiftUI
import RealityKit
import ARKit

/// A reality view that contains all hand-tracking entities.
struct HandTrackingView: View {
    /// The main body of the view.
    var body: some View {
        RealityView { content in
            makeHandEntities(in: content)
        }
    }

    /// Creates the entity that contains all hand-tracking entities.
    @MainActor
    func makeHandEntities(in content: any RealityViewContentProtocol) {
        // Add the left hand.
        let leftHand = Entity()
        leftHand.components.set(HandTrackingComponent(chirality: .left))
        content.add(leftHand)

        // Add the right hand.
        let rightHand = Entity()
        rightHand.components.set(HandTrackingComponent(chirality: .right))
        content.add(rightHand)
    }
}
