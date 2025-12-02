/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that calculates and then passes data to material instances that render drop shadows on objects.
*/

import Combine
import Metal
import RealityKit
import RealityKitContent

final class DropShadowSystem: System {
    static let commandQueue: MTLCommandQueue? = makeCommandQueue(labeled: "Drop Shadow Command Queue")
    /// Compute pipeline corresponding to the Metal compute shader function `updateDropShadowMap`.
    ///
    /// See `DropShadowComputeShader.metal`.
    let updateDropShadowMapPipeline: MTLComputePipelineState = makeComputePipeline(named: "updateDropShadowMap")!
    
    let dropShadowMapDimensions = SIMD2<Int>(1024, 1024)
    let dropShadowMap: LowLevelTexture
    let dropShadowMapResource: TextureResource
    let threadgroups: MTLSize
    let threadsPerThreadgroup: MTLSize
    var dropShadowParameterBuffer: MTLBuffer
    var dropShadowParameterBufferLength: Int = 13
    
    let rockFriendQuery = EntityQuery(where: .has(RockPickupComponent.self))
    let dropShadowReceiverQuery = EntityQuery(where: .has(DropShadowReceiverModelComponent.self))
    var subscriptions: [AnyCancellable] = .init()

    required init (scene: Scene) {
        // Create the parameter buffer.
        guard let dropShadowParameterBuffer = metalDevice?
            .makeBuffer(length: dropShadowParameterBufferLength * MemoryLayout<DropShadowComputeParams>.stride) else {
            fatalError("Failed to create parameter buffer.")
        }
        self.dropShadowParameterBuffer = dropShadowParameterBuffer
        
        // Create the low-level texture.
        do {
            dropShadowMap = try LowLevelTexture(descriptor: LowLevelTexture.Descriptor(
                // Use the `MTLPixelFormat.rgba16Float` pixel format so that each pixel can store 4 half-precision values.
                pixelFormat: .rgba16Float,
                width: dropShadowMapDimensions.x,
                height: dropShadowMapDimensions.y,
                // Set the texture usage to `MTLTextureUsage.shaderWrite` since the compute shader only ever writes to the texture,
                // and never reads from it.
                textureUsage: [.shaderWrite]))
            dropShadowMapResource = try TextureResource(from: dropShadowMap)
        } catch {
            fatalError("Failed to create drop shadow textures: \(error)")
        }
        
        // Calculate the number of threadgroups to dispatch.
        // https://developer.apple.com/documentation/metal/calculating-threadgroup-and-grid-sizes
        let threadWidth = updateDropShadowMapPipeline.threadExecutionWidth
        let threadHeight = updateDropShadowMapPipeline.maxTotalThreadsPerThreadgroup / threadWidth
        self.threadsPerThreadgroup = MTLSize(width: threadWidth, height: threadHeight, depth: 1)
        self.threadgroups = MTLSize(width: (dropShadowMapDimensions.x + threadWidth - 1) / threadWidth,
                                    height: (dropShadowMapDimensions.y + threadHeight - 1) / threadHeight,
                                    depth: 1)

        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: DropShadowReceiverComponent.self) {
            self.onDidAddDropShadowReceiverComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor func onDidAddDropShadowReceiverComponent (event: ComponentEvents.DidAdd) {
        setShadowReceiverModelsRecursively(entity: event.entity)
    }

    func update(context: SceneUpdateContext) {
        // Guard for the physics root and the character entity.
        guard let physicsRoot = context.first(withComponent: PhysicsSimulationComponent.self)?.entity,
                let character = context.first(withComponent: CharacterMovementComponent.self)?.entity else { return }
        
        // Get the matrix that transforms from world space to level space.
        let worldToLevelMatrix = physicsRoot.transformMatrix(relativeTo: nil).inverse
        
        // Ray cast downward to determine where the character's shadow lands.
        if let (characterPosition, characterShadowYPosition) = calculateParametersForShadow(character, physicsRoot) {
            
            // Ray cast downward for each rock friend to determine where their shadows land.
            var rockFriendPositions = [(position: SIMD3<Float>, shadowYPosition: Float)]()
            for rockFriend in context.entities(matching: rockFriendQuery, updatingSystemWhen: .rendering) {
                if let (friendPosition, friendShadowYPosition) = calculateParametersForShadow(rockFriend, physicsRoot) {
                    rockFriendPositions.append((friendPosition, friendShadowYPosition))
                }
            }
            
            // To run a compute shader on the GPU, first enqueue the commands to be run sequentially on the GPU.
            if let commandBuffer = Self.commandQueue?.makeCommandBuffer(),
               let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                
                // Enqueue the command buffer.
                commandBuffer.enqueue()
                
                // Resize the compute parameter buffer if it does not have enough capacity
                // to store drop shadow parameters for all the rock friends and the character.
                let dropShadowParameterCount = rockFriendPositions.count + 1
                if dropShadowParameterCount > dropShadowParameterBufferLength {
                    if let newBuffer = metalDevice?.makeBuffer(length: dropShadowParameterCount * MemoryLayout<DropShadowComputeParams>.stride) {
                        dropShadowParameterBuffer = newBuffer
                        dropShadowParameterBufferLength = dropShadowParameterCount
                    }
                }
                // Update the compute parameter buffer.
                let dropShadowParameters = unsafe dropShadowParameterBuffer.contents().bindMemory(to: DropShadowComputeParams.self,
                                                                                                  capacity: dropShadowParameterCount)
                unsafe dropShadowParameters[0] = DropShadowComputeParams(
                    sourcePosition: characterPosition,
                    sourceShadowYPosition: characterShadowYPosition,
                    sourceShadowRadius: GameSettings.characterShadowRadius
                )
                for parameterIndex in 1..<dropShadowParameterCount {
                    unsafe dropShadowParameters[parameterIndex] = DropShadowComputeParams(
                        sourcePosition: rockFriendPositions[parameterIndex - 1].position,
                        sourceShadowYPosition: rockFriendPositions[parameterIndex - 1].shadowYPosition,
                        sourceShadowRadius: GameSettings.rockFriendShadowRadius
                    )
                }
                
                // Set the compute pipeline state to the `updateDropShadowMap` kernel in `DropShadowComputeShader.metal`.
                computeEncoder.setComputePipelineState(updateDropShadowMapPipeline)
                // Encode the drop shadow parameter buffer as the first input parameter by setting it with an index of 0.
                computeEncoder.setBuffer(dropShadowParameterBuffer, offset: 0, index: 0)
                // Encode the parameter count as the second input parameter to the by setting it with an index of 1.
                var parameterCount = UInt(dropShadowParameterCount)
                unsafe computeEncoder.setBytes(&parameterCount, length: MemoryLayout<UInt>.size, index: 1)
                // Encode the drop shadow map texture as the third input parameter by setting it with an index of 2.
                computeEncoder.setTexture(dropShadowMap.replace(using: commandBuffer), index: 2)
                // Encode dispatching the compute shader.
                computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
                
                // Stop encoding compute commands and commit them to run on the GPU.
                computeEncoder.endEncoding()
                commandBuffer.commit()
            }
            
            // Send the shadow parameters to the shader.
            for dropShadowReceiver in context.entities(matching: dropShadowReceiverQuery, updatingSystemWhen: .rendering) {
                setShadowShaderParameters(entity: dropShadowReceiver, worldToLevelMatrix: worldToLevelMatrix)
            }
        }
    }
    
    @MainActor
    fileprivate func calculateParametersForShadow(_ entity: Entity, _ physicsRoot: Entity)
        -> (characterPosition: SIMD3<Float>, shadowYPosition: Float)? {
        // Get the origin relative to the physics root entity.
        let origin = entity.position(relativeTo: physicsRoot)
        
        // Perform a ray cast against the scene downward from the origin.
        return if let hit = entity.scene?.raycast(
            origin: origin,
            direction: [0, -1, 0],
            query: .nearest,
            // Use a mask to make sure you're only performing a ray cast against entities in the shadow receiver group.
            mask: GameCollisionGroup.shadowReceiver.collisionGroup,
            relativeTo: physicsRoot
        ).first {
            // Return a tuple when the ray cast is successful.
            (origin, hit.position.y)
        } else {
            nil
        }
    }

    @MainActor
    func setShadowReceiverModelsRecursively (entity: Entity) {
        if let modelComponent = entity.components[ModelComponent.self] {
            for (index, material) in modelComponent.materials.enumerated() {
                // Skip the material if it's not a graph material that takes a drop shadow map input.
                guard var shaderGraphMaterial = material as? ShaderGraphMaterial,
                      shaderGraphMaterial.parameterNames.contains("DropShadowMap") else { continue }

                // Add a drop-shadow receiver model component to the entity if it doesn't have one.
                if !entity.components.has(DropShadowReceiverModelComponent.self) {
                    entity.components.set(DropShadowReceiverModelComponent())
                    
                    // Pass the drop shadow texture to the material.
                    // You only need to do this once since the compute shader updates the texture on the GPU
                    // such that those changes automatically propagate to any materials that reference the texture.
                    try? shaderGraphMaterial.setParameter(handle: ShaderGraphMaterial.parameterHandle(name: "DropShadowMap"),
                                                          value: .textureResource(dropShadowMapResource))
                    entity.components[ModelComponent.self]?.materials[index] = shaderGraphMaterial
                }

                // Store the material index of the shadow shader.
                entity.components[DropShadowReceiverModelComponent.self]?.shadowMaterialIndices.insert(index)
            }
        }

        for child in entity.children {
            setShadowReceiverModelsRecursively(entity: child)
        }
    }
    
    /// Sets the shadow shader parameters for all materials on an entity.
    @MainActor
    func setShadowShaderParameters (entity: Entity, worldToLevelMatrix: simd_float4x4) {
        if let dropShadowReceiverModelComponent = entity.components[DropShadowReceiverModelComponent.self] {
            // Iterate through each shadow material on this model and apply the shadow shader parameters.
            for materialIndex in dropShadowReceiverModelComponent.shadowMaterialIndices {
                guard var shaderGraphMaterial = entity.components[ModelComponent.self]?.materials[materialIndex] as? ShaderGraphMaterial else {
                    continue
                }

                try? shaderGraphMaterial.setParameter(handle: dropShadowReceiverModelComponent.worldToLevelMatrixParameterHandle,
                                                      value: .float4x4(worldToLevelMatrix))

                entity.components[ModelComponent.self]?.materials[materialIndex] = shaderGraphMaterial
            }
        }
    }
}
