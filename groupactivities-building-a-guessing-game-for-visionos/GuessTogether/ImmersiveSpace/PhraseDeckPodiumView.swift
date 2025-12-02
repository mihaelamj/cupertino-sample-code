/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view of a podium the game presents in its immersive space, which positions the current
  secret phrase in front of the active player.
*/

import RealityKit
import Spatial
import SwiftUI

struct PhraseDeckPodiumView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        RealityView { content, attachments  in
            attachments.entity(for: "PhraseDeckView").map(content.add)
        } update: { content, _ in
            content.entities.first.map(updatePodiumPose(_:))
        } attachments: {
            Attachment(id: "PhraseDeckView") {
                PhraseDeckView()
            }
        }
        .frame(depth: 0)
    }
    
    func updatePodiumPose(_ phraseDeckPodium: Entity) {
        let podiumPosition = GameTemplate.playerPosition.translated(by: Vector3D(x: 0.6))
        phraseDeckPodium.position = .init(podiumPosition)
    }
}
