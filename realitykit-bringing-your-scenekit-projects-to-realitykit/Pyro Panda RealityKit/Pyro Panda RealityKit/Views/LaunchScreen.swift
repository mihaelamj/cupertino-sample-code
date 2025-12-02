/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The launch screen for visionOS.
*/

import SwiftUI
import RealityKit
import PyroPanda

#if os(visionOS)
struct LaunchScreen: View {
    @Environment(AppModel.self) internal var appModel

    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        VStack {
            GeometryReader3D { geometry in
                RealityView { content in
                    let world = await makeWorld()
                    let portal = makePortal(world: world)

                    content.add(world)
                    content.add(portal)

                    // Position the portal at the back of the view.
                    let contentSize = content.convert(geometry.size, from: .local, to: .scene)
                    portal.position.z = -contentSize.z / 2
                    world.position.z = -contentSize.z / 2
                }
            }
            ToggleImmersiveSpaceButton { newState in
                if newState == .open {
                    openWindow(id: "gameStatus")
                    // Close the main window after 0.2 seconds.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.2))
                        dismissWindow(id: "mainWindow")
                    }
                } else {
                    openWindow(id: "mainWindow")
                    // Close the dismiss window after 0.2 seconds.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.2))
                        dismissWindow(id: "gameStatus")
                    }
                }
            }.padding()

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Backgrounds"))
        .environment(appModel)
    }

    private func makeWorld() async -> Entity {
        let world = Entity(components: WorldComponent())

        guard let launchScene = try? await Entity(
            named: "Launcher", in: pyroPandaBundle
        ) else { fatalError() }

        launchScene.findEntity(named: "enemy")?.components.set(PortalCrossingComponent())

        world.addChild(launchScene)
        return world
    }

    private func makePortal(world: Entity) -> Entity {
        let portalComponent = PortalComponent(
            target: world,
            clippingMode: .plane(.positiveZ),
            crossingMode: .plane(.positiveZ)
        )
        let portalModel = ModelComponent(
            mesh: .generatePlane(width: 0.3, height: 0.3, cornerRadius: 0.15),
            materials: [PortalMaterial()]
        )
        // Always display the portal on top of the UI.
        let portalSortGroup = ModelSortGroupComponent(group: .planarUIAlwaysInFront, order: 0)

        return Entity(components: [portalComponent, portalModel, portalSortGroup])
    }
}

#Preview {
    LaunchScreen()
        .environment(AppModel())
}
#endif
