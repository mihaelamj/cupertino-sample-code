/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows the immersive environment after enabling it.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content.
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }

            /// Create a docking entity as the docking anchor.
            let dockingEntity = Entity()

            /// Create a docking-region component to customize the docking region.
            var dockingRegionComponent = DockingRegionComponent()
            // Set the docking-region width to 9.6 meters.
            dockingRegionComponent.width = 9.6
            // Set the docking position, in meters.
            dockingEntity.position = [0, 2, -10]

            // Attach the docking-region component to the docking entity.
            dockingEntity.components.set(dockingRegionComponent)

            content.add(dockingEntity)
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
