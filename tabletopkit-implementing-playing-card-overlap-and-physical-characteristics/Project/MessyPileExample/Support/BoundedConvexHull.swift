/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class for implementing a bounded convex hull support plane solver.
*/

import Spatial
import TabletopKit

// MARK: - Plane3D helpers

func makeTopPlane(boundingBox: Rect3DFloat,
                  pose: Pose3DFloat) -> Plane3DFloat {
    let normal = Vector3DFloat(x: 0, y: 1, z: 0).rotated(by: pose.rotation)
    let topPoint = Point3DFloat(x: 0, y: boundingBox.max.y, z: 0).applying(pose)
    return Plane3DFloat(normal: normal, dot: simd_dot(normal.vector, topPoint.vector))
}

func makePose(pose2d: TableVisualState.Pose2D,
              boundingBox: Rect3DFloat) -> Pose3D {
    let center = Point3D(x: pose2d.position.x, y: Double(-boundingBox.min.y), z: pose2d.position.z)
    let rotationY = Rotation3D(angle: pose2d.rotation, axis: .y)
    return Pose3D(position: center, rotation: rotationY)
}

func makePoseOnPlane(pose2d: TableVisualState.Pose2D,
                     boundingBox: Rect3DFloat,
                     plane: Plane3DFloat) -> Pose3D {
    let center = plane.pointOnPlane(at: pose2d.position) - plane.normal * boundingBox.min.y
    let rotationY = Rotation3D(angle: pose2d.rotation, axis: .y)
    let normalXZ = Vector3DFloat(projecting: plane.normal)
    let normalXZLen = normalXZ.length
    if normalXZLen < 0.000_000_01 {
        return Pose3D(position: Point3D(center), rotation: rotationY)
    }
    let angleXZ = normalXZLen < 1.0 ? asin(normalXZLen) : .pi / 2
    let axisXZ = Vector3D(x: plane.normal.z / normalXZLen, y: 0, z: -plane.normal.x / normalXZLen) // normal x y
    let rotationXZ = Rotation3D(angle: .init(radians: angleXZ), axis: .init(axisXZ))
    return Pose3D(position: Point3D(center), rotation: rotationXZ * rotationY)
}

// MARK: - BoundedConvexHull

// A bounded convex hull is a minimum volume, single height per XZ point,
// polygonal mesh, that encloses all contents within a `ConvexBoundary2D`.
class BoundedConvexHull {
    let boundary: ConvexBoundary2D
    var vertices: [Point3DFloat]

    init(boundary: ConvexBoundary2D) {
        assert(!boundary.isEmpty)
        assert(boundary.isValid && boundary.corners.count >= 3)
        self.boundary = boundary
        // Add all corners of the boundary at height zero.
        self.vertices = boundary.corners.map { $0.deproject(height: 0) }
    }
}

extension BoundedConvexHull {
    func addPlanarPolygon(polygon: ConvexBoundary2D, plane: Plane3DFloat) -> Bool {
        let clippedPolygon = polygon.intersection(with: boundary)
        if clippedPolygon.isEmpty {
            return false
        }
        vertices.append(contentsOf: clippedPolygon.corners.map { plane.pointOnPlane(at: $0) })
        return true
    }

    func findSupportPlane(at center: Point3DFloat) -> Plane3DFloat {
        let epsilon: Float = 0.0001
        let epsilonSquared = epsilon * epsilon
        
        // Find the vertex with largest height Y, which must be on the convex hull.
        var topVertex = center.deproject(height: -Float.greatestFiniteMagnitude)
        for vertex in vertices where topVertex.y < vertex.y {
            topVertex = vertex
        }
        if topVertex.y <= 0 {
            return Plane3DFloat(normal: .init(x: 0, y: 1, z: 0), dot: 0)
        }
        
        // Determine which corners form a 2D triangle that contains the `center` point.
        let edgeIndex = findEdgeIndexSurrounding(corners: boundary.corners, center: center, from: Point3DFloat(projecting: topVertex))
        let surroundingCorners = [ boundary.corners[edgeIndex], boundary.corners[boundary.nextIndex(edgeIndex)] ]
        
        // Find the maximum height vertex at the two surrounding corners.
        var planeVertices = [
            topVertex,
            surroundingCorners[0].deproject(height: -Float.greatestFiniteMagnitude),
            surroundingCorners[1].deproject(height: -Float.greatestFiniteMagnitude)
        ]
        for vertex in vertices {
            for idx in 0..<2 {
                let distanceSqr = (Point3DFloat(projecting: vertex) - surroundingCorners[idx]).lengthSquared
                if distanceSqr < epsilonSquared {
                    if planeVertices[idx + 1].y < vertex.y {
                        planeVertices[idx + 1] = vertex
                    }
                }
            }
        }
        
        // Return the plane of the convex hull face that contains the `center` point.
        return findConvexHullPlaneContaining(center: center, startingPlaneVertices: planeVertices)
    }
}

extension BoundedConvexHull {
    // Returns the index of the boundary edge that, together with vertex,
    // form a triangle that contains `center`, assuming vertex and center
    // are inside the boundary.
    //
    // That is, `vertex`, `corners[edgeIndex]`, and `corners[(edgeIndex+1)%count]`
    // form a triangle that contains `center`.
    internal func findEdgeIndexSurrounding(corners: [Point3DFloat],
                                           center: Point3DFloat,
                                           from vertex: Point3DFloat) -> Int {
        let vertexToCenter = center - vertex
        if vertexToCenter.lengthSquared.isZero {
            return 0
        }
        let right = Vector3DFloat(x: -vertexToCenter.z, y: 0, z: vertexToCenter.x)
        var prevCornerDotRight = simd_dot((corners[corners.count - 1] - vertex).vector, right.vector)
        var prevCornerIsOnVertex = (corners[corners.count - 1] - vertex).lengthSquared.isZero
        for nextCornerIndex in 0..<corners.count {
            let cornerFromVertex = corners[nextCornerIndex] - vertex
            let cornerIsOnVertex = cornerFromVertex.lengthSquared.isZero
            let cornerDotRight = simd_dot(cornerFromVertex.vector, right.vector)
            if prevCornerDotRight <= 0 && !prevCornerIsOnVertex && cornerDotRight > 0 {
                return (nextCornerIndex > 0 ? nextCornerIndex : corners.count) - 1
            }
            prevCornerDotRight = cornerDotRight
            prevCornerIsOnVertex = cornerIsOnVertex
        }
        return 0
    }

    internal func findTopVertexAndRemainingVertices(vertices: [Point3DFloat],
                                                    plane: Plane3DFloat) -> (topVertex: Point3DFloat,
                                                                             remainingVertices: [Point3DFloat])? {
        
        // This epsilon should be large enough to drop the vertices
        // used to generate plane.
        let epsilon: Float = 0.000_001
        var maxHeight = -Float.greatestFiniteMagnitude
        var topVertex: Point3DFloat = .zero
        var remainingVertices: [Point3DFloat] = []
        for vertex in vertices {
            let height = plane.distance(to: vertex)
            if height < epsilon {
                continue
            }
            if maxHeight < height {
                maxHeight = height
                topVertex = vertex
            }
            remainingVertices.append(vertex)
        }
        if maxHeight <= 0 {
            return nil
        }
        return (topVertex: topVertex, remainingVertices: remainingVertices)
    }

    // This is a QuickHull algorithm limited to only traverse toward
    // the single convex hull face that contains `center`.
    internal func findConvexHullPlaneContaining(center: Point3DFloat,
                                                startingPlaneVertices: [Point3DFloat]) -> Plane3DFloat {
        assert(startingPlaneVertices.count == 3)
        var planeVertices = startingPlaneVertices
        var plane = Plane3DFloat(point0: planeVertices[0], point1: planeVertices[2], point2: planeVertices[1])
        assert(plane.normal.y > 0)
        var testedAllVerticesAgainstPlane = false
        while !testedAllVerticesAgainstPlane {
            
            // Given three starting vertices known to be on the convex hull and
            // surrounding center, iteratively find the highest point from the
            // plane in whichever segment of the triangle will remain surrounding
            // the center.
            var remainingVertices: [Point3DFloat] = vertices
            testedAllVerticesAgainstPlane = true
            while let result = findTopVertexAndRemainingVertices(vertices: remainingVertices, plane: plane) {
                testedAllVerticesAgainstPlane = false
                let corners = planeVertices.map { Point3DFloat(projecting: $0) }
                let edgeIndex = findEdgeIndexSurrounding(corners: corners, center: center, from: Point3DFloat(projecting: result.topVertex))
                let replaceCornerIndex = edgeIndex > 0 ? edgeIndex - 1 : 2
                planeVertices[replaceCornerIndex] = result.topVertex
                remainingVertices = result.remainingVertices
                plane = Plane3DFloat(point0: planeVertices[0], point1: planeVertices[2], point2: planeVertices[1])
                assert(plane.normal.y > 0)
            }
            
            // Unless you've tested all vertices against the initial plane and
            // found none above, it remains possible that there were vertices
            // in triangle segments you skipped that are now above this new plane.
            // It's very likely that the first iteration locates at least one or two
            // of the three correct support plane vertices, and that no more than
            // three iterations will locate all.
        }
        return plane
    }
}
