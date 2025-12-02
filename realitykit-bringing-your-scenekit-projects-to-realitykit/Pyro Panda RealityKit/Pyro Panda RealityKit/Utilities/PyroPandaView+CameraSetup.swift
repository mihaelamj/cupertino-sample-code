/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The parts of `PyroPandaView` that set up the world camera.
*/

import RealityKit
import WorldCamera

extension PyroPandaView {
    /// Performs any necessary setup of the world camera.
    /// - Parameter target: The entity to orient the camera toward.
    @discardableResult
    func setupWorldCamera(target: Entity) -> Entity {
        // Set the available bounds for the camera orientation.
        let elevationBounds: ClosedRange<Float> = (.zero)...(.pi / 3)
        let initialElevation: Float = .pi / 14

        // Create a world camera component, which acts as a target camera,
        // where it repositions the scene to orient toward the owning entity.
        var worldCameraComponent = WorldCameraComponent(
            azimuth: .pi,
            elevation: initialElevation,
            radius: 3,
            bounds: WorldCameraComponent.CameraBounds(elevation: elevationBounds)
        )
        #if os(visionOS)
        // The way that RealityKit orients immersive views isn't the same as a portal.
        // This offset brings the target a bit closer to the center of the view.
        // The system also modifies this in `PyroPandaView/RealityView`.
        worldCameraComponent.targetOffset = [0, -0.75, 0]
        #else
        worldCameraComponent.targetOffset = [0, 0.5, 0]
        #endif

        let worldCamera = Entity(components:
            worldCameraComponent,
            FollowComponent(targetId: target.id, smoothing: [3, 1.2, 3])
        )
        worldCamera.name = "camera"
        #if !os(visionOS)
        worldCamera.addChild(Entity(components: PerspectiveCameraComponent()))
        #endif

        let simulationParent = PhysicsSimulationComponent.nearestSimulationEntity(for: target)
        worldCamera.setParent(simulationParent ?? target.parent)
        return worldCamera
    }
}
