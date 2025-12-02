/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that holds the 3D content for the app's immersive space.
*/

import ARKit
import SwiftUI
import RealityKit

let cubeMeshInteractionID = "CubeMeshInteraction"

/// A view that lets people place cubes in their surroundings based on the scene reconstruction mesh.
///
/// A tap on any of the meshes drops a cube above it.
struct CubeMeshInteraction: View {
    @Environment(EntityModel.self) var model
    @Environment(\.openWindow) var openWindow

    var body: some View {
        RealityView { content, attachments in
            content.add(model.setupContentEntity())

            if let window = attachments.entity(for: "window") {
                window.position = .init(x: 0, y: 1.0, z: -1.0)
                content.add(window)
            }
        } attachments: {
            Attachment(id: "window") {
                VStack(spacing: 20) {
                    Text("Tap to Place Cubes")
                        .font(.largeTitle)
                    if let errorMessage = model.errorMessage {
                        Text("An error occurred: \(errorMessage)")
                    }
                }
                .padding(50)
                .glassBackgroundEffect()
            }
        }
        .task {
            do {
                if model.dataProvidersAreSupported {
                    if model.isReadyToRun {
                        try await model.session.run([model.sceneReconstruction, model.handTracking])
                    }
                } else {
                    model.errorMessage = "Data providers not supported."
                }
            } catch {
                model.errorMessage = "Failed to start session: \(error)"
                logger.error("Failed to start session: \(error)")
            }
        }
        .task {
            await model.processHandUpdates()
        }
        .task {
            await model.monitorSessionEvents()
        }
        .task(priority: .low) {
            await model.processReconstructionUpdates()
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            let location3D = value.convert(value.location3D, from: .local, to: .scene)
            model.addCube(tapLocation: location3D)
        })
    }
}
