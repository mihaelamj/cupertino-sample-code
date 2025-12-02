/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main UI that presents the game view.
*/

import SwiftUI
import RealityKit
import RealityKitContent
import TabletopKit
import GroupActivities
import Foundation
import os
import GameplayKit

@MainActor
struct PlaygroundView: View {
    @Environment(Playground.self) var playground
    let volumetricRoot: Entity

    init() {
        volumetricRoot = Entity()
        volumetricRoot.name = "volumetricRoot"
    }

    var body: some View {
        GeometryReader3D { proxy3D in
            RealityView { (content: inout RealityViewContent) in
                content.entities.append(volumetricRoot)
                // Set the root at the base of the volume.
                let frame = content.convert(proxy3D.frame(in: .local), from: .local, to: volumetricRoot)
                volumetricRoot.transform.translation.y = frame.min.y
                volumetricRoot.addChild(playground.root)
            }
        }.toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                Button(action: { Task { try! await PlaygroundActivity().activate() } }) {
                    Label("SharePlay", systemImage: "shareplay")
                }
            }
        }.tabletopGame(playground.game, parent: playground.root) { _ in
            Interaction(game: playground.game)
        }.task {
            for await session in PlaygroundActivity.sessions() {
                playground.game.coordinateWithSession(session)
            }
        }
    }
}
