/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions for generating mesh data.
*/

import RealityKit

struct PortalMeshDescriptor {
    var width: Float
    var height: Float
    var depth: Float
    var cornerRadius: Float
    var cornerSegmentCount: Int = 20
    var bendRadius: Float
    var bendSegmentCount: Int
}

@MainActor
func generatePortalMesh (descriptor: PortalMeshDescriptor) -> MeshResource {
    let bendSegmentAngle = 1 / Float(descriptor.bendSegmentCount) * .pi / 2
    let cornerSegmentAngle = 1 / Float(descriptor.cornerSegmentCount) * .pi / 2
    
    var positions: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    
    var index: UInt32 = 0
    
    // Generate the top corners of the portal.
    for segmentIndex in 0...descriptor.cornerSegmentCount {
        let angle: Float = Float(segmentIndex) * cornerSegmentAngle
        let widthOffset = (1 - sin(angle)) * descriptor.cornerRadius
        let heightOffset = (1 - cos(angle)) * descriptor.cornerRadius
        
        positions.append([-descriptor.width / 2 + widthOffset, descriptor.height - heightOffset, -descriptor.depth / 2])
        positions.append([descriptor.width / 2 - widthOffset, descriptor.height - heightOffset, -descriptor.depth / 2])
        
        if segmentIndex > 0 {
            indices.append(contentsOf: [index + 0, index + 2, index + 1, index + 1, index + 2, index + 3])
            index += 2
        }
    }
    
    // Generate the bend in the portal.
    for segmentIndex in 0...descriptor.bendSegmentCount {
        let angle: Float = Float(segmentIndex) * bendSegmentAngle
        let heightOffset = (1 - sin(angle)) * descriptor.bendRadius
        let depthOffset = (1 - cos(angle)) * descriptor.bendRadius
        
        positions.append([-descriptor.width / 2, heightOffset, -descriptor.depth / 2 + depthOffset])
        positions.append([descriptor.width / 2, heightOffset, -descriptor.depth / 2 + depthOffset])

        indices.append(contentsOf: [index + 0, index + 2, index + 1, index + 1, index + 2, index + 3])
        index += 2
    }
    
    // Generate the bottom corners of the portal.
    for segmentIndex in 0...descriptor.cornerSegmentCount {
        let angle: Float = Float(segmentIndex) * cornerSegmentAngle
        let widthOffset = (1 - cos(angle)) * descriptor.cornerRadius
        let depthOffset = (1 - sin(angle)) * descriptor.cornerRadius
        
        positions.append([-descriptor.width / 2 + widthOffset, 0, descriptor.depth / 2 - depthOffset])
        positions.append([descriptor.width / 2 - widthOffset, 0, descriptor.depth / 2 - depthOffset])
        
        indices.append(contentsOf: [index + 0, index + 2, index + 1, index + 1, index + 2, index + 3])
        index += 2
    }

    var meshDescriptor = MeshDescriptor()
    meshDescriptor.positions = .init(positions)
    meshDescriptor.primitives = .triangles(indices)

    let meshResource = try! MeshResource.generate(from: [meshDescriptor])
    return meshResource
}
