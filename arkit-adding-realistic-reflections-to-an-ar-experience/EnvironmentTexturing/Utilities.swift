/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience extensions on system types.
*/

import Foundation
import ARKit

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
}

// MARK: - ARSCNView extensions

extension ARSCNView {
    
    func smartHitTest(_ point: CGPoint) -> ARHitTestResult? {
        
        // Perform the hit test.
        let results = hitTest(point, types: [.existingPlaneUsingGeometry])
        
        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }) {
            return existingPlaneUsingGeometryResult
        }
        
        // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
        let infinitePlaneResults = hitTest(point, types: .existingPlane)
        
        if let infinitePlaneResult = infinitePlaneResults.first {
            return infinitePlaneResult
        }
        
        // 3. As a final fallback, check for a result on estimated planes.
        return results.first(where: { $0.type == .estimatedHorizontalPlane })
    }
    
}

extension SCNNode {
    var extents: SIMD3<Float> {
        let (min, max) = boundingBox
        return SIMD3<Float>(max) - SIMD3<Float>(min)
    }
}

// MARK: - float4x4 extensions

extension float4x4 {
    init(translation vector: SIMD3<Float>) {
        self.init([1, 0, 0, 0],
                  [0, 1, 0, 0],
                  [0, 0, 1, 0],
                  [vector.x, vector.y, vector.z, 1])
    }
    
    var translation: SIMD3<Float> {
        let translation = columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}
