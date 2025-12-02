/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model of the sculpting.
*/

import SwiftUI
import RealityKit
import ARKit

@MainActor @Observable
final class SculptingToolModel {
    // Min and max radii of the sculpting tool.
    let minRadius: Float = 0.01
    let maxRadius: Float = 0.5

    var rootEntity: Entity? = nil // The root entity in the RealityView.

    let sculptingTool = Entity(components: [ModelComponent(mesh: .generateSphere(radius: 0.001), materials: [SimpleMaterial()]),
                                            OpacityComponent(opacity: 0.01)])
    
    var sculptingEntity: AnchorEntity? = nil
    var trackingStateIndicator: ModelEntity? = nil
    
    var additiveIcon: Entity? = nil
    var subtractiveIcon: Entity? = nil
    var enlargeIcon: Entity? = nil
    var reduceIcon: Entity? = nil

    var hapticsModel: HapticsModel? = nil

    // Raycast from the accessory to the add/subtract elements of the toolbar to swap to
    // the different controls.
    func selectToolbarElement(sculptingEntity: AnchorEntity) {
        guard let scene = sculptingEntity.scene else {
            return
        }
        let raycastOrigin = sculptingEntity.position(relativeTo: nil)
        let raycastForward = -simd_make_float3(sculptingEntity.transformMatrix(relativeTo: nil).columns.2)
        if let raycastHit = scene.raycast(origin: raycastOrigin, direction: raycastForward, length: 10, relativeTo: nil).first {
            if raycastHit.entity.name == "AdditiveIcon" {
                sculptingTool.components[SculptingToolComponent.self]?.mode = .add
            } else if raycastHit.entity.name == "SubtractiveIcon" {
                sculptingTool.components[SculptingToolComponent.self]?.mode = .remove
            } else if raycastHit.entity.name == "EnlargeIcon" {
                if let radius = sculptingTool.components[SculptingToolComponent.self]?.radius {
                    sculptingTool.components[SculptingToolComponent.self]?.radius = simd_clamp(radius + 0.01, minRadius, maxRadius)
                }
            } else if raycastHit.entity.name == "ReduceIcon" {
                if let radius = sculptingTool.components[SculptingToolComponent.self]?.radius {
                    sculptingTool.components[SculptingToolComponent.self]?.radius = simd_clamp(radius - 0.01, minRadius, maxRadius)
                }
            }
        }
    }
    
    // Display the toolbar, offsetting based on the hand holding the accessory.
    @MainActor
    func displayToolbar(transform: Transform, accessoryAnchor: AccessoryAnchor) {
        guard let chirality = accessoryAnchor.heldChirality else {
            return
        }
        
        guard let additiveIcon = additiveIcon,
              let subtractiveIcon = subtractiveIcon,
              let reduceIcon = reduceIcon,
              let enlargeIcon = enlargeIcon else {
            return
        }
                
        let zTranslation: Float = -0.1
        let xTranslation: Float = {
            switch chirality {
            case .left:
                return 0.05 // Display a toolbar 5 cm to the right.
            case .right:
                return -0.05 // Display a toolbar 5 cm to the left.
            default:
                return 0.0 // Do not offset the toolbar.
            }
        }()
        
        subtractiveIcon.isEnabled = true
        additiveIcon.isEnabled = true
        reduceIcon.isEnabled = true
        enlargeIcon.isEnabled = true
        
        additiveIcon.position = transform.translation + SIMD3<Float>(xTranslation, 0.05, zTranslation)
        subtractiveIcon.position = transform.translation + SIMD3<Float>(xTranslation, 0, zTranslation)
        reduceIcon.position = transform.translation + SIMD3<Float>(xTranslation, -0.05, zTranslation)
        enlargeIcon.position = transform.translation + SIMD3<Float>(xTranslation, -0.10, zTranslation)
    }
    
    func handlePalettePress(pressed: Bool) {
        guard let sculptingEntity = sculptingEntity else {
            return
        }
        
        guard let accessoryAnchor = getAccessoryAnchor(entity: sculptingEntity) else {
            return
        }
        
        if pressed {
            Task { @MainActor in
                displayToolbar(transform: sculptingTool.transform, accessoryAnchor: accessoryAnchor)
            }
        } else {
            selectToolbarElement(sculptingEntity: sculptingEntity)
            additiveIcon?.isEnabled = false
            subtractiveIcon?.isEnabled = false
            reduceIcon?.isEnabled = false
            enlargeIcon?.isEnabled = false
        }
    }
    
    // Show an indicator when tracking is non 6 DOF.
    // Gets an ARKit AccessoryAnchor from a RealityKit AnchorEntity
    // and extracts relevant interaction data for warning of possible bad data.
    func updateTrackingStateIndicatorIfDirty(sculptingEntity: AnchorEntity) {
        guard let accessoryAnchor = getAccessoryAnchor(entity: sculptingEntity) else {
            return
        }
        
        if var sculptingToolComponent = sculptingTool.components[SculptingToolComponent.self] {
            if sculptingToolComponent.trackingState != accessoryAnchor.trackingState {
                sculptingToolComponent.trackingState = accessoryAnchor.trackingState
                // If we have lost 6 DOF tracking, display the tracking warning
                if accessoryAnchor.trackingState != .positionOrientationTracked {
                    let trackingColor = [SimpleMaterial(color: trackingStateColor[sculptingToolComponent.trackingState]!, isMetallic: false)]
                    trackingStateIndicator?.isEnabled = true
                    trackingStateIndicator?.components[ModelComponent.self]?.materials = trackingColor
                } else {
                    trackingStateIndicator?.isEnabled = false
                }
            }
        }
    }
    
    // Every frame, update the interactions with in-app content
    // from the sculpting tool to the virtual clay.
    func updateSculptingTool() {
        guard let sculptingEntity = sculptingEntity else {
            return
        }
        guard let rootEntity = rootEntity, let matrix = try? sculptingEntity.transform(from: rootEntity) else {
            return
        }
        // Update the sculpting tool with the sculpting tool's transform.
        // This ensures it can carve into the correct part of virtual clay.
        sculptingTool.transform = Transform(matrix: simd_float4x4(matrix))
        
        // Show the tracking state indicator if it's not position and orientation tracked.
        updateTrackingStateIndicatorIfDirty(sculptingEntity: sculptingEntity)
    }
    
    // Add the attachment to the root entity.
    func addEntityAttachmentToRoot(entity: Entity, name: String) {
        entity.position = .zero
        entity.isEnabled = false
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: .init(repeating: 0.05))]))
        entity.name = name
        rootEntity?.addChild(entity)
    }

}
