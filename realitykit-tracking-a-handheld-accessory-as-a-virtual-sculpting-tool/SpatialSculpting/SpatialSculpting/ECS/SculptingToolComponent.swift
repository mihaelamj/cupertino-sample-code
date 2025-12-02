/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that determines sculpting parameters.
*/

import RealityKit
import ARKit
import UIKit

enum SculptingMode {
    case add
    case remove
}

let sculptingColor: [SculptingMode: UIColor] = [
    .add: .green,
    .remove: .red
]

struct SculptingToolComponent: Component {
    let sculptor: MarchingCubesMeshSculptor
    var mode: SculptingMode = .remove
    var radius: Float = 0.035
    var isActive: Bool = false
    var reset: Bool = true
    var clear: Bool = false
    var heldChirality: Accessory.Chirality? = nil
    var trackingState: AccessoryAnchor.TrackingState = .untracked
    var tooltip: ModelEntity? = nil
    var previousPosition: SIMD3<Float>? = nil
    var saveToTexture: (MTLTexture, @Sendable () throws -> Void)? = nil
    var loadFromTexture: MTLTexture? = nil
}

// Update the sculpture depending on user-accessory interactions.
struct SculptingToolSystem: ComputeSystem {
    let query = EntityQuery(where: .has(SculptingToolComponent.self))
    
    func update(computeContext: inout ComputeUpdateContext) {
        for sculptingTool in computeContext.sceneUpdateContext.scene.performQuery(query) {
            guard var sculptingToolComponent = sculptingTool.components[SculptingToolComponent.self] else {
                continue
            }
            
            sculptingToolComponent.radius = simd_clamp(sculptingToolComponent.radius, 0.01, 0.5)
            
            // Display the current sculpting mode and size on the tooltip.
            sculptingToolComponent.tooltip?.components[ModelComponent.self]?.materials = [
                SimpleMaterial(color: sculptingColor[sculptingToolComponent.mode]!, isMetallic: false)
            ]
            sculptingToolComponent.tooltip?.scale = SIMD3<Float>(repeating: sculptingToolComponent.radius)

            // Reset the sculpture to a box.
            if sculptingToolComponent.reset {
                sculptingToolComponent.sculptor.reset(computeContext: &computeContext)
                sculptingToolComponent.reset = false
            }

            // Empty the sculpture to a clean slate.
            if sculptingToolComponent.clear {
                sculptingToolComponent.sculptor.clear(computeContext: &computeContext)
                sculptingToolComponent.clear = false
            }

            // Load in a sculpture from a file.
            if let sourceTexture = sculptingToolComponent.loadFromTexture {
                sculptingToolComponent.sculptor.load(sourceTexture: sourceTexture, computeContext: &computeContext)
                sculptingToolComponent.loadFromTexture = nil
            }

            // Sculpt a capsule from the previous position to the current position.
            if sculptingToolComponent.isActive {
                let mode: sculpt_mode = sculptingToolComponent.mode == .add ? add : remove
                let toolPositionAndRadius = SIMD4<Float>(sculptingTool.position, sculptingToolComponent.radius)
                let previousPositionAndActive: SIMD4<Float>
                if let previousPosition = sculptingToolComponent.previousPosition {
                     previousPositionAndActive = SIMD4<Float>(previousPosition, 1)
                } else {
                    previousPositionAndActive = .zero
                }

                let sculptParams = SculptParams(mode: mode,
                                                toolPositionAndRadius: toolPositionAndRadius,
                                                previousPositionAndHasPosition: previousPositionAndActive)
                sculptingToolComponent.sculptor.sculpt(sculptParams: sculptParams, computeContext: &computeContext)
            }

            // Save the completed sculpture to a file.
            if let (destinationTexture, onCompletion) = sculptingToolComponent.saveToTexture {
                sculptingToolComponent.sculptor.save(destinationTexture: destinationTexture,
                                                     computeContext: &computeContext,
                                                     onCompletion: onCompletion)
                sculptingToolComponent.saveToTexture = nil
            }

            sculptingToolComponent.previousPosition = sculptingTool.isActive ? sculptingTool.position : nil

            sculptingTool.components.set(sculptingToolComponent)
        }
    }
}
