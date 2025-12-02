/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A compute system which dispatches compute commands every frame.
*/

import Metal
import RealityKit

// A structure that contains the context a `ComputeSystem` needs to dispatch compute commands in every frame.
struct ComputeUpdateContext {
    // The scene update context.
    let sceneUpdateContext: SceneUpdateContext
    // The command buffer for the current frame.
    let commandBuffer: MTLCommandBuffer

    init(sceneUpdateContext: SceneUpdateContext, commandBuffer: MTLCommandBuffer) {
        self.sceneUpdateContext = sceneUpdateContext
        self.commandBuffer = commandBuffer
    }

    mutating func computeEncoder() -> MTLComputeCommandEncoder? {
        if let existingEncoder = _computeEncoder {
            return existingEncoder
        }
        _blitEncoder?.endEncoding()
        _blitEncoder = nil
        _computeEncoder = commandBuffer.makeComputeCommandEncoder()
        return _computeEncoder
    }

    mutating func blitEncoder() -> MTLBlitCommandEncoder? {
        if let existingEncoder = _blitEncoder {
            return existingEncoder
        }
        _computeEncoder?.endEncoding()
        _computeEncoder = nil
        _blitEncoder = commandBuffer.makeBlitCommandEncoder()
        return _blitEncoder
    }

    mutating func endEncoding() {
        _computeEncoder?.endEncoding()
        _blitEncoder?.endEncoding()
    }

    // The compute command encoder for the current frame.
    private var _computeEncoder: MTLComputeCommandEncoder? = nil
    // The blit command encoder for the current frame.
    private var _blitEncoder: MTLBlitCommandEncoder? = nil
}

// A protocol that enables its adoptees to dispatch their own compute commands in every frame.
protocol ComputeSystem {
    @MainActor
    func update(computeContext: inout ComputeUpdateContext)
}

// A component that contains a `ComputeSystem`.
struct ComputeSystemComponent: Component {
    let computeSystem: ComputeSystem
}

// A class that updates the `ComputeSystem` of each `ComputeSystemComponent` with `ComputeUpdateContext` in every frame.
class ComputeDispatchSystem: System {
    // The application's command queue.
    //
    // A single, global command queue to use throughout the entire application.
    static let commandQueue: MTLCommandQueue? = makeCommandQueue(labeled: "Compute Dispatch System Command Queue")
    
    // The query this system uses to get all entities with a `ComputeSystemComponent` in every frame.
    let query = EntityQuery(where: .has(ComputeSystemComponent.self))
    
    required init(scene: Scene) { }
    
    // Updates all compute systems with the current frame's `ComputeUpdateContext`.
    func update(context: SceneUpdateContext) {
        // Get all entities with a `ComputeSystemComponent` in every frame.
        let computeSystemEntities = context.entities(matching: query, updatingSystemWhen: .rendering)
        
        // Create the command buffer and compute encoder responsible for dispatching all compute commands this frame.
        guard let commandBuffer = Self.commandQueue?.makeCommandBuffer() else {
            return
        }
        
        // Dispatch all compute systems to encode their compute commands.
        var computeContext = ComputeUpdateContext(sceneUpdateContext: context,
                                                  commandBuffer: commandBuffer)
        for computeSystemEntity in computeSystemEntities {
            if let computeSystemComponent = computeSystemEntity.components[ComputeSystemComponent.self] {
                computeSystemComponent.computeSystem.update(computeContext: &computeContext)
            }
        }
        
        // Stop encoding compute commands and commit them to run on the GPU.
        computeContext.endEncoding()
        commandBuffer.commit()
    }
}
