/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Generates compute commands to dispatch for marching cubes.
*/

import RealityKit
import Metal

@MainActor
struct MarchingCubesMeshSculptor {
    // Compute pipeline corresponding to the Metal compute shader function `reset`.
    //
    // See `SculptVoxelsComputeShader.metal`.
    private let resetPipeline: MTLComputePipelineState!
    // Compute pipeline corresponding to the Metal compute shader function `clearVolume`.
    //
    // See `SculptVoxelsComputeShader.metal`.
    private let clearPipeline: MTLComputePipelineState!
    // Compute pipeline corresponding to the Metal compute shader function `sculpt`.
    //
    // See `SculptVoxelsComputeShader.metal`.
    private let sculptPipeline: MTLComputePipelineState!
    
    let marchingCubesMesh: MarchingCubesMesh
    
    init(marchingCubesMesh: MarchingCubesMesh) {
        resetPipeline = makeComputePipeline(named: "reset")
        clearPipeline = makeComputePipeline(named: "clearVolume")
        sculptPipeline = makeComputePipeline(named: "sculpt")
        self.marchingCubesMesh = marchingCubesMesh
    }
    
    func reset(computeContext: inout ComputeUpdateContext) {
        let volume = marchingCubesMesh.voxelVolume
        // Get the command buffer and compute encoder for dispatching commands to the GPU.
        guard let computeEncoder = computeContext.computeEncoder() else {
            return
        }

        // Set the compute shader pipeline to `reset`.
        computeEncoder.setComputePipelineState(resetPipeline)
        
        // Pass a writable version of the voxels texture to the compute shader.
        computeEncoder.setTexture(volume.voxelTexture, index: 0)
        
        // Pass the volume parameters to the compute shader.
        var volumeParams = volume.volumeParams
        computeEncoder.setBytes(&volumeParams, length: MemoryLayout<VolumeParams>.size, index: 1)
        
        // Dispatch the compute shader.
        computeEncoder.dispatchThreadgroups(volume.idealThreadgroupCount,
                                            threadsPerThreadgroup: volume.idealThreadsPerThreadgroup)
        
        // Update the marching cubes mesh.
        marchingCubesMesh.update(computeContext: &computeContext)
    }
    
    func clear(computeContext: inout ComputeUpdateContext) {
        let volume = marchingCubesMesh.voxelVolume
        // Get the command buffer and compute encoder for dispatching commands to the GPU.
        guard let computeEncoder = computeContext.computeEncoder() else {
            return
        }

        // Set the compute shader pipeline to `clear`.
        computeEncoder.setComputePipelineState(clearPipeline)

        // Pass a writable version of the voxels texture to the compute shader.
        computeEncoder.setTexture(volume.voxelTexture, index: 0)

        // Pass the volume parameters to the compute shader.
        var volumeParams = volume.volumeParams
        computeEncoder.setBytes(&volumeParams, length: MemoryLayout<VolumeParams>.size, index: 1)

        // Dispatch the compute shader.
        computeEncoder.dispatchThreadgroups(volume.idealThreadgroupCount,
                                            threadsPerThreadgroup: volume.idealThreadsPerThreadgroup)

        // Update the marching cubes mesh.
        marchingCubesMesh.update(computeContext: &computeContext)
    }

    func sculpt(sculptParams: SculptParams, computeContext: inout ComputeUpdateContext) {
        let volume = marchingCubesMesh.voxelVolume
        // Get the command buffer and compute encoder for dispatching commands to the GPU.
        guard let computeEncoder = computeContext.computeEncoder() else {
            return
        }

        // Set the compute shader pipeline to `sculpt`.
        computeEncoder.setComputePipelineState(sculptPipeline)

        // Pass readable and writable versions of the voxels texture to the compute shader.
        computeEncoder.setTexture(volume.voxelTexture, index: 0)
        computeEncoder.setTexture(volume.voxelTexture, index: 1)
        
        // Pass the volume and sculpt parameters to the compute shader.
        var volumeParams = volume.volumeParams
        var sculptParams = sculptParams
        computeEncoder.setBytes(&volumeParams, length: MemoryLayout<VolumeParams>.size, index: 2)
        computeEncoder.setBytes(&sculptParams, length: MemoryLayout<SculptParams>.size, index: 3)
        
        // Dispatch the compute shader.
        computeEncoder.dispatchThreadgroups(volume.idealThreadgroupCount,
                                            threadsPerThreadgroup: volume.idealThreadsPerThreadgroup)
        
        // Update the marching cubes mesh.
        marchingCubesMesh.update(computeContext: &computeContext)
    }

    func save(destinationTexture: MTLTexture, computeContext: inout ComputeUpdateContext, onCompletion: @Sendable @escaping () throws -> Void) {
        guard let blitEncoder = computeContext.blitEncoder() else {
            return
        }
        
        blitEncoder.copy(from: marchingCubesMesh.voxelVolume.voxelTexture, to: destinationTexture)

        computeContext.commandBuffer.addCompletedHandler { _ in
            do {
                try onCompletion()
            } catch {
                print("Error saving texture: \(error)")
            }
        }
    }

    func load(sourceTexture: MTLTexture, computeContext: inout ComputeUpdateContext) {
        guard let blitEncoder = computeContext.blitEncoder() else {
            return
        }
        blitEncoder.copy(from: sourceTexture, to: marchingCubesMesh.voxelVolume.voxelTexture)

        // Update the marching cubes mesh.
        marchingCubesMesh.update(computeContext: &computeContext)
    }
}
