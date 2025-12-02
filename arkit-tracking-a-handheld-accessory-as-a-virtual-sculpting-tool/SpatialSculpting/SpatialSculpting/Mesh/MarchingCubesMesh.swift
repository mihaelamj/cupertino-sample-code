/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An updatable mesh representation using marching cubes.
*/
import RealityKit
import Metal

struct MarchingCubesMeshChunk {
    let mesh: LowLevelMesh
    var params: MarchingCubesParams
    let clearThreadgroups: MTLSize
    let clearThreadsPerThreadgroup: MTLSize
    let marchThreadgroups: MTLSize
    let marchThreadsPerThreadgroup: MTLSize
}

@MainActor
final class MarchingCubesMesh {
    private let maxVertexCapacityPerMeshChunk = 8_500_000
    private let maxVerticesPerVoxel: UInt32 = 1
    
    // The compute pipeline that corresponds to the Metal compute shader function, `march`.
    //
    // See `MarchingCubesCompute.metal`.
    private let marchPipeline: MTLComputePipelineState = makeComputePipeline(named: "march")!
    // Compute pipeline corresponding to the Metal compute shader function `clear`.
    //
    // See `MarchingCubesCompute.metal`.
    private let clearPipeline: MTLComputePipelineState = makeComputePipeline(named: "clear")!
    
    let voxelVolume: VoxelVolume
    var meshChunks: [MarchingCubesMeshChunk] = []
    let triangleTableBuffer: MTLBuffer
    let counterBuffer: MTLBuffer
    var isoValue: Float = 0
    
    class func createMeshChunk(vertexCapacity: Int, fromZ: UInt32, toZ: UInt32, voxelVolume: VoxelVolume) throws -> MarchingCubesMeshChunk {
        // Determine the voxel start position and dimensions for this mesh chunk.
        let chunkVoxelStartPosition = voxelVolume.voxelStartPosition + Float(fromZ) * [0, 0, voxelVolume.voxelSize.z]
        let chunkDimensions = SIMD3<UInt32>(voxelVolume.dimensions.x, voxelVolume.dimensions.y, toZ - fromZ + 1)
        
        // Create mesh parameters for this chunk.
        let params = MarchingCubesParams(dimensions: voxelVolume.dimensions,
                                         voxelSize: voxelVolume.voxelSize,
                                         voxelStartPosition: voxelVolume.voxelStartPosition,
                                         chunkDimensions: chunkDimensions,
                                         chunkStartZ: fromZ,
                                         maxVertexCount: UInt32(vertexCapacity))
        
        // Create the low-level mesh for this chunk.
        let meshDescriptor = LowLevelMesh.Descriptor(vertexCapacity: vertexCapacity,
                                                     vertexAttributes: MeshVertex.vertexAttributes,
                                                     vertexLayouts: MeshVertex.vertexLayouts,
                                                     indexCapacity: vertexCapacity)
        let mesh = try LowLevelMesh(descriptor: meshDescriptor)

        // Compute the chunk's bounding box.
        let bounds = BoundingBox(min: chunkVoxelStartPosition - voxelVolume.voxelSize / 2,
                                 max: chunkVoxelStartPosition + voxelVolume.voxelSize * SIMD3<Float>(chunkDimensions) + voxelVolume.voxelSize / 2)
        
        // Assign mesh parts.
        mesh.parts.replaceAll([LowLevelMesh.Part(indexCount: vertexCapacity, bounds: bounds)])
        
        // Calculate thread groups.
        let clearThreadsPerThreadgroup = MTLSize(width: 512, height: 1, depth: 1)
        let clearThreadgroups = MTLSize(width: (Int(params.maxVertexCount) + clearThreadsPerThreadgroup.width - 1) / clearThreadsPerThreadgroup.width,
                                        height: 1,
                                        depth: 1)
        
        let marchThreadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 8)
        let marchWidth = (Int(chunkDimensions.x - 1) + marchThreadsPerThreadgroup.width - 1) / marchThreadsPerThreadgroup.width
        let marchHeight = (Int(chunkDimensions.y - 1) + marchThreadsPerThreadgroup.height - 1) / marchThreadsPerThreadgroup.height
        let marchDepth = (Int(chunkDimensions.z - 1) + marchThreadsPerThreadgroup.depth - 1) / marchThreadsPerThreadgroup.depth
        let marchThreadgroups = MTLSize(width: marchWidth, height: marchHeight, depth: marchDepth)

        // Create the mesh chunk.
        let meshChunk = MarchingCubesMeshChunk(mesh: mesh,
                                               params: params,
                                               clearThreadgroups: clearThreadgroups,
                                               clearThreadsPerThreadgroup: clearThreadsPerThreadgroup,
                                               marchThreadgroups: marchThreadgroups,
                                               marchThreadsPerThreadgroup: marchThreadsPerThreadgroup)
        
        return meshChunk
    }
    
    init(voxelVolume: VoxelVolume) throws {
        self.voxelVolume = voxelVolume
        
        // Assert that the volume isn't so large that it's impossible to create a chunk per slice, taking overflow into account.
        assert(voxelVolume.dimensions.x * voxelVolume.dimensions.y * maxVerticesPerVoxel * 2 < maxVertexCapacityPerMeshChunk)
        
        // Iterate through each slice, splitting them among multiple mesh chunks if necessary.
        var vertexCount = 0
        var previousZ = UInt32(0)
        for currentZ in 0..<voxelVolume.dimensions.z {
            // Count the maximum number of vertices needed to render this slice of the volume.
            vertexCount += Int(voxelVolume.dimensions.x * voxelVolume.dimensions.y * maxVerticesPerVoxel)
            
            // Create a new mesh chunk if the vertex count exceeds the maximum vertex count.
            if vertexCount >= maxVertexCapacityPerMeshChunk {
                // Build a low-level mesh to support the number of slices processed thus far.
                self.meshChunks.append(try MarchingCubesMesh.createMeshChunk(vertexCapacity: maxVertexCapacityPerMeshChunk,
                                                                             fromZ: previousZ,
                                                                             toZ: currentZ - 1,
                                                                             voxelVolume: voxelVolume))
                
                // Update previous slice.
                previousZ = currentZ - 1
                
                // Reset the vertex count, including any overflow.
                vertexCount = vertexCount % maxVertexCapacityPerMeshChunk
            }
        }
        self.meshChunks.append(try MarchingCubesMesh.createMeshChunk(vertexCapacity: vertexCount,
                                                                     fromZ: previousZ,
                                                                     toZ: voxelVolume.dimensions.z - 1,
                                                                     voxelVolume: voxelVolume))
        
        // Create a Metal buffer with the triangle table data.
        let tableLength = MarchingCubesData.triangleTable.count * MemoryLayout<UInt64>.stride
        self.triangleTableBuffer = metalDevice!.makeBuffer(bytes: MarchingCubesData.triangleTable, length: tableLength)!

        // Create a Metal counter buffer.
        self.counterBuffer = metalDevice!.makeBuffer(length: MemoryLayout<UInt32>.stride)!
    }
    
    func update(computeContext: inout ComputeUpdateContext) {
        // Run marching cubes on each mesh chunk.
        guard let computeEncoder = computeContext.computeEncoder() else {
            return
        }
        for var meshChunk in meshChunks {
            // Reset the vertex and index buffers.
            computeEncoder.setComputePipelineState(clearPipeline)
            
            computeEncoder.setBuffer(meshChunk.mesh.replace(bufferIndex: 0, using: computeContext.commandBuffer), offset: 0, index: 0)
            computeEncoder.setBuffer(meshChunk.mesh.replaceIndices(using: computeContext.commandBuffer), offset: 0, index: 1)
            computeEncoder.setBytes(&meshChunk.params, length: MemoryLayout<MarchingCubesParams>.size, index: 2)
            
            computeEncoder.dispatchThreadgroups(meshChunk.clearThreadgroups, threadsPerThreadgroup: meshChunk.clearThreadsPerThreadgroup)
            
            // Run marching cubes.
            computeEncoder.setComputePipelineState(marchPipeline)
            
            computeEncoder.setBuffer(meshChunk.mesh.replace(bufferIndex: 0, using: computeContext.commandBuffer), offset: 0, index: 0)
            computeEncoder.setBuffer(meshChunk.mesh.replaceIndices(using: computeContext.commandBuffer), offset: 0, index: 1)
            computeEncoder.setTexture(voxelVolume.voxelTexture, index: 2)
            computeEncoder.setBytes(&meshChunk.params, length: MemoryLayout<MarchingCubesParams>.size, index: 3)
            computeEncoder.setBuffer(triangleTableBuffer, offset: 0, index: 4)
            counterBuffer.contents().storeBytes(of: 0, as: UInt32.self)
            computeEncoder.setBuffer(counterBuffer, offset: 0, index: 5)
            computeEncoder.setBytes(&isoValue, length: MemoryLayout<Float>.size, index: 6)
            
            computeEncoder.dispatchThreadgroups(meshChunk.marchThreadgroups, threadsPerThreadgroup: meshChunk.marchThreadsPerThreadgroup)
        }
    }
}

