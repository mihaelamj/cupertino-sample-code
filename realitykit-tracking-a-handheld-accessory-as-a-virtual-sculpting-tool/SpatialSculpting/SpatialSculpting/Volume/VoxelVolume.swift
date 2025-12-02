/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The volumetric representation of the sculpture.
*/

import RealityKit
import Metal

enum VoxelVolumeError: Error {
    case failedToCreateTexture
}

// A 3D texture that represents a volume.
// The value of each voxel reprents the distance from an isosurface.
@MainActor
final class VoxelVolume {
    var voxelTexture: MTLTexture

    let dimensions: SIMD3<UInt32>
    let voxelSize: SIMD3<Float>
    let voxelStartPosition: SIMD3<Float>
    
    var volumeParams: VolumeParams {
        VolumeParams(dimensions: dimensions, voxelSize: voxelSize, voxelStartPosition: voxelStartPosition)
    }
    
    let idealThreadgroupCount: MTLSize
    let idealThreadsPerThreadgroup: MTLSize

    init(dimensions: SIMD3<UInt32>, voxelSize: SIMD3<Float>, voxelStartPosition: SIMD3<Float>) throws {
        self.dimensions = dimensions
        self.voxelSize = voxelSize
        self.voxelStartPosition = voxelStartPosition

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type3D
        textureDescriptor.pixelFormat = .r32Float
        textureDescriptor.width = Int(dimensions.x)
        textureDescriptor.height = Int(dimensions.y)
        textureDescriptor.depth = Int(dimensions.z)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        
        guard let voxelTexture = metalDevice?.makeTexture(descriptor: textureDescriptor) else {
            throw VoxelVolumeError.failedToCreateTexture
        }
        
        self.voxelTexture = voxelTexture

        self.idealThreadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 8)
        self.idealThreadgroupCount = MTLSize(width: (Int(dimensions.x) + idealThreadsPerThreadgroup.width - 1) / idealThreadsPerThreadgroup.width,
                                             height: (Int(dimensions.y) + idealThreadsPerThreadgroup.height - 1) / idealThreadsPerThreadgroup.height,
                                             depth: (Int(dimensions.z) + idealThreadsPerThreadgroup.depth - 1) / idealThreadsPerThreadgroup.depth)
    }
}
