/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience extensions on ARSCNView for raycasting
*/

import ARKit

extension ARSCNView {
    
    // MARK: - Raycast

    func smartRaycast(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: SIMD3<Float>? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal]) -> ARRaycastResult? {
        // Perform raycasting.
        guard let query = raycastQuery(from: point, allowing: .existingPlaneGeometry, alignment: .any) else {
            fatalError("Raycast unexpectedly returned nil.")
        }
        let geometryPlaneResults = session.raycast(query)

        // 1. Check for a result on an existing plane using geometry.
        if let geometryPlaneResult = geometryPlaneResults.first(where: { result in
            guard let planeAnchor = result.anchor as? ARPlaneAnchor else { return false }
            return allowedAlignments.contains(planeAnchor.alignment)
        }) {
            return geometryPlaneResult
        }
        
        if infinitePlane {
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            guard let query = raycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .any) else {
                fatalError("Raycast unexpectedly returned nil.")
            }
            let infinitePlaneResults = session.raycast(query)
            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor,
                   allowedAlignments.contains(planeAnchor.alignment) {
                    if planeAnchor.alignment == .vertical {
                        // Return the first vertical plane hit test result.
                        return infinitePlaneResult
                    } else {
                        // For horizontal planes we only want to return a hit test result
                        // if it is close to the current object's position.
                        if let objectY = objectPosition?.y {
                            let planeY = infinitePlaneResult.worldTransform.translation.y
                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                                return infinitePlaneResult
                            }
                        } else {
                            return infinitePlaneResult
                        }
                    }
                }
            }
        }
        
        // Perform raycasting.
        guard let query = raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any) else {
            fatalError("Raycast unexpectedly returned nil.")
        }
        let estimatedPlaneResults = session.raycast(query)

        // 3. As a final fallback, check for a result on estimated planes.
        let vResult = estimatedPlaneResults.first { $0.targetAlignment == .vertical }
        let hResult = estimatedPlaneResults.first { $0.targetAlignment == .horizontal }
        switch (allowedAlignments.contains(.horizontal), allowedAlignments.contains(.vertical)) {
        case (true, false):
            return hResult
        case (false, true):
            // Allow fallback to horizontal because we assume that objects meant for vertical placement
            // (like a picture) can always be placed on a horizontal surface, too.
            return vResult ?? hResult
        case (true, true):
            if hResult != nil && vResult != nil {
                return distanceToCamera(hResult!) < distanceToCamera(vResult!) ? hResult : vResult
            } else {
                return hResult ?? vResult
            }
        default:
            return nil
        }
    }

    // Calculate distance from camera to the detected surface.
    private func distanceToCamera(_ result: ARRaycastResult) -> Float {
        guard let cameraTransform = session.currentFrame?.camera.transform else {
            return Float.infinity
        }
        // Convert the camera position to `SIMD<Float>`.
        let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                          cameraTransform.columns.3.y,
                                          cameraTransform.columns.3.z)
        let rayPosition = result.worldTransform.translation
        return simd_distance(cameraPosition, rayPosition)
    }
}
