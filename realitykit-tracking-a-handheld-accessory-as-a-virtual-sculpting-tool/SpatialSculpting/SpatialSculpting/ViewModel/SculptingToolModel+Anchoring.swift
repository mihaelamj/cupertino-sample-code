/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Functions related to anchoring with RealityKit and ARKit.
*/

import ARKit
import RealityKit
@preconcurrency import GameController

@MainActor let trackingStateColor: [AccessoryAnchor.TrackingState: UIColor] = [
    .positionOrientationTracked: .green,
    .orientationTracked: .yellow,
    .positionOrientationTrackedLowAccuracy: .orange,
    .untracked: .red
]

// Get the ARKit accessory anchor from a RealityKit AnchorEntity.
@MainActor func getAccessoryAnchor(entity: AnchorEntity) -> AccessoryAnchor? {
    if let accessoryAnchor = entity.components[ARKitAnchorComponent.self]?.anchor as? AccessoryAnchor {
        return accessoryAnchor
    }
    return nil
}

extension SculptingToolModel {
    
    // Add a visual tooltip to indicate where sculpting occurs.
    // Also add a tracking state indicator to indicate when tracking may be
    // failing due to reduced sensor coverage.
    @MainActor
    func addSculptingTooltip(to entity: AnchorEntity) {
        let tooltipEntity = ModelEntity(mesh: .generateSphere(radius: 1.0), materials: [SimpleMaterial(color: .purple, isMetallic: true)])
        entity.addChild(tooltipEntity)
        sculptingTool.components[SculptingToolComponent.self]?.tooltip = tooltipEntity
        
        trackingStateIndicator = ModelEntity(mesh: .generateSphere(radius: 0.02), materials:
                                            [SimpleMaterial(color: trackingStateColor[.positionOrientationTracked]!,
                                            isMetallic: false)])
        trackingStateIndicator?.transform = .init(translation: SIMD3<Float>(0.1, 0, 0))

        if let trackingStateIndicator = trackingStateIndicator {
            entity.addChild(trackingStateIndicator)
        }
        sculptingEntity = entity
    }
    
    // Anchor via AnchorEntity to a GCDevice.
    // Set up stylus or controller inputs.
    @MainActor
    func setupSpatialAccessory(device: GCDevice, hapticsModel: HapticsModel) async throws {
        let source = try await AnchoringComponent.AccessoryAnchoringSource(device: device)
        
        guard let location = source.locationName(named: "aim") ?? source.locationName(named: "tip") else {
            return
        }
        
        let sculptingEntity = AnchorEntity(.accessory(from: source, location: location),
                                           trackingMode: .predicted,
                                           physicsSimulation: .none)
        
        sculptingEntity.name = "SculptingEntity"
        
        rootEntity?.addChild(sculptingEntity)
        
        addSculptingTooltip(to: sculptingEntity)
        
        // Set up inputs to take in controller or stylus style inputs.
        if let stylus = device as? GCStylus {
            setupStylusInputs(stylus: stylus, hapticsModel: hapticsModel)
        } else if let controller = device as? GCController {
            setupControllerInputs(controller: controller, hapticsModel: hapticsModel)
        }
    }
    
}
