/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure for implementing convex polygon intersection, along with
  supporting types.
*/

import Spatial
import TabletopKit

// MARK: - Plane3D

struct Plane3DFloat {
    let normal: Vector3DFloat
    let dot: Float
}

extension Plane3DFloat {
    func distance(to point: Point3DFloat) -> Float {
        return simd_dot(point.vector, normal.vector) - dot
    }

    func contains(_ point: Point3DFloat) -> Bool {
        return distance(to: point) <= 0
    }

    func strictlyContains(_ point: Point3DFloat) -> Bool {
        return distance(to: point) < 0
    }
}

extension Plane3DFloat {
    // Construct a plane from three counterclockwise points.
    init(point0: Point3DFloat, point1: Point3DFloat, point2: Point3DFloat) {
        let v01 = point1 - point0
        let v02 = point2 - point0
        normal = Vector3DFloat(simd_cross(v01.vector, v02.vector)).normalized
        dot = simd_dot(point0.vector, normal.vector)
    }
}

// The TabletopKit 2D plane of interest is X,Z (where Y is up).
extension Plane3DFloat {
    func height(at point2d: Point3DFloat) -> Float {
        if normal.y == 0.0 {
            return !contains(point2d) ? -Float.infinity : Float.infinity
        }
        return (dot - point2d.x * normal.x - point2d.z * normal.z) / normal.y
    }

    func pointOnPlane(at point2d: Point3DFloat) -> Point3DFloat {
        point2d.deproject(height: height(at: point2d))
    }

    func height(at point2d: TableVisualState.Point2D) -> Float {
        height(at: Point3DFloat(point2d))
    }

    func pointOnPlane(at point2d: TableVisualState.Point2D) -> Point3DFloat {
        pointOnPlane(at: Point3DFloat(point2d))
    }
}

// MARK: - ConvexBoundary2D

// A 2D convex polygon with precalculated edge tests.
struct ConvexBoundary2D {
    // The corners must always be in clockwise (+X to +Z) order. Y is ignored.
    let corners: [Point3DFloat]
    
    // The count of edges and corner must be equal (edges.count == corners.count),
    // and `edges` must use
    // `makeEdgePlane(point1: corners[i], point2: corners[i + 1 < corners.count ? i + 1 : 0])`.
    let edges: [Plane3DFloat]
}

extension ConvexBoundary2D {
    init(corners: [Point3DFloat]) {
        self.corners = corners
        self.edges = Array(0..<corners.count).map { cornerIndex in
            ConvexBoundary2D.makeEdgePlane(point1: corners[cornerIndex],
                                           point2: corners[cornerIndex + 1 < corners.count ? cornerIndex + 1 : 0])
        }
    }

    var isEmpty: Bool { corners.isEmpty }
    var isValid: Bool { edges.count == corners.count }

    func nextIndex(_ index: Int) -> Int {
        return ConvexBoundary2D.nextIndex(index, count: corners.count)
    }
    func prevIndex(_ index: Int) -> Int {
        return ConvexBoundary2D.prevIndex(index, count: corners.count)
    }
}

extension ConvexBoundary2D {
    static var empty: ConvexBoundary2D {
        return ConvexBoundary2D(corners: [], edges: [])
    }
}

extension ConvexBoundary2D {
    func intersection(with boundary: ConvexBoundary2D) -> ConvexBoundary2D {
        
        // Intersect by `[otherEdgeIndex][cornerIndex]`.
        let distanceOtherEdgeToCorner: [[Float]] = boundary.edges.map { edge in corners.map { corner in edge.distance(to: corner) } }
        let allCornersOutsideAnyOtherEdge = distanceOtherEdgeToCorner.contains(where: { $0.allSatisfy { $0 >= 0 } })
        if allCornersOutsideAnyOtherEdge {
            return ConvexBoundary2D.empty
        }
        
        // Intersect by `[edgeIndex][otherCornerIndex]`.
        let distanceEdgeToOtherCorner: [[Float]] = edges.map { edge in boundary.corners.map { corner in edge.distance(to: corner) } }
        let allOtherCornersOutsideAnyEdge = distanceEdgeToOtherCorner.contains(where: { $0.allSatisfy { $0 >= 0 } })
        if allOtherCornersOutsideAnyEdge {
            return ConvexBoundary2D.empty
        }
        let allCornersInsideAllOtherEdges = distanceOtherEdgeToCorner.allSatisfy { $0.allSatisfy { $0 <= 0 } }
        if allCornersInsideAllOtherEdges {
            return self
        }
        let allOtherCornersInsideAllEdges = distanceEdgeToOtherCorner.allSatisfy { $0.allSatisfy { $0 <= 0 } }
        if allOtherCornersInsideAllEdges {
            return boundary
        }

        // To generate the intersection, use the simple option of clipping
        // the corners and edges to each of `boundary.edges[]` sequentially.
        var intersectionCorners: [Point3DFloat] = corners
        var intersectionEdges: [Plane3DFloat] = edges
        let maxClippedCount = corners.count + boundary.corners.count
        intersectionCorners.reserveCapacity(maxClippedCount)
        intersectionEdges.reserveCapacity(maxClippedCount)
        for otherEdge in boundary.edges {
            clip(corners: &intersectionCorners, edges: &intersectionEdges, to: otherEdge)
        }
        return ConvexBoundary2D(corners: intersectionCorners, edges: intersectionEdges)
    }
}

// MARK: - ConvexBoundary2D helpers

func makeConvexBoundary2D(boundingBox: Rect3DFloat,
                          pose2d: TableVisualState.Pose2D) -> ConvexBoundary2D {
    let origin = Point3DFloat(pose2d.position)
    let rotation = Angle2DFloat(pose2d.rotation)
    let axes = rotation.yRotatedAxes
    let corners: [Point3DFloat] = [
        origin + axes.x * boundingBox.max.x + axes.z * boundingBox.max.z,
        origin + axes.x * boundingBox.min.x + axes.z * boundingBox.max.z,
        origin + axes.x * boundingBox.min.x + axes.z * boundingBox.min.z,
        origin + axes.x * boundingBox.max.x + axes.z * boundingBox.min.z
    ]
    return ConvexBoundary2D(corners: corners)
}

func makeConvexBoundary2DOfTopPlane(boundingBox: Rect3DFloat,
                                    pose: Pose3DFloat) -> ConvexBoundary2D {
    let topCornersOS: [Point3DFloat] = [
        boundingBox.max,
        Point3DFloat(x: boundingBox.min.x, y: boundingBox.max.y, z: boundingBox.max.z),
        Point3DFloat(x: boundingBox.min.x, y: boundingBox.max.y, z: boundingBox.min.z),
        Point3DFloat(x: boundingBox.max.x, y: boundingBox.max.y, z: boundingBox.min.z)
    ]
    let corners = topCornersOS.map { $0.applying(pose) }
    return ConvexBoundary2D(corners: corners)
}

// MARK: - ConvexBoundary2D internal

extension ConvexBoundary2D {
    // Returns the boundary line with the outside to the left
    // from `point2` relative to `point1`, and ignoring Y.
    internal static func makeEdgePlane(point1: Point3DFloat,
                                       point2: Point3DFloat) -> Plane3DFloat {
        let dir = point2 - point1
        let left = Vector3DFloat(x: dir.z, y: 0, z: -dir.x)
        let normal = left.normalized
        let dot = simd_dot(point1.vector, normal.vector)
        return .init(normal: normal, dot: dot)
    }

    internal func intersection(between corner1: Point3DFloat,
                               and corner2: Point3DFloat,
                               distance1: Float,
                               distance2: Float) -> Point3DFloat {
        if distance1 == distance2 {
            return corner1
        }
        let lerpFactor = distance2 == 0 ? 1 : -distance1 / (distance2 - distance1)
        return corner1.interpolate(to: corner2, lerpFactor: lerpFactor)
    }

    internal func clip(corners: inout [Point3DFloat],
                       edges: inout [Plane3DFloat],
                       to edge: Plane3DFloat) {
        let distanceToCorners = corners.map { edge.distance(to: $0) }
        
        // Clipping by the previous edges may leave no corners outside.
        if distanceToCorners.allSatisfy({ $0 <= 0 }) {
            return
        }
        
        // The inside corners and outside corners must always form
        // contiguous (but possibly wrapped) sequences.
        let cornerIndexFirstOutside = distanceToCorners[0] >= 0 ?
            ConvexBoundary2D.nextIndex(distanceToCorners.lastIndex(where: { $0 < 0 })!, count: distanceToCorners.count) :
            distanceToCorners.firstIndex(where: { $0 >= 0 })!
        let cornerIndexLastOutside = distanceToCorners[0] >= 0 ?
            ConvexBoundary2D.prevIndex(distanceToCorners.firstIndex(where: { $0 < 0 })!, count: distanceToCorners.count) :
            distanceToCorners.lastIndex(where: { $0 >= 0 })!
        let cornerIndexLastInside = ConvexBoundary2D.prevIndex(cornerIndexFirstOutside, count: distanceToCorners.count)
        let cornerIndexFirstInside = ConvexBoundary2D.nextIndex(cornerIndexLastOutside, count: distanceToCorners.count)
        let intersectionFirst = intersection(between: corners[cornerIndexLastInside],
                                             and: corners[cornerIndexFirstOutside],
                                             distance1: distanceToCorners[cornerIndexLastInside],
                                             distance2: distanceToCorners[cornerIndexFirstOutside])
        let intersectionLast = intersection(between: corners[cornerIndexLastOutside],
                                            and: corners[cornerIndexFirstInside],
                                            distance1: distanceToCorners[cornerIndexLastOutside],
                                            distance2: distanceToCorners[cornerIndexFirstInside])
        if cornerIndexFirstOutside <= cornerIndexLastOutside {
            corners.replaceSubrange(cornerIndexFirstOutside...cornerIndexLastOutside, with: [intersectionFirst, intersectionLast])
            edges.replaceSubrange(cornerIndexFirstOutside..<cornerIndexLastOutside, with: [edge])
            return
        }
        if cornerIndexLastInside < corners.count - 1 {
            corners.removeSubrange(cornerIndexFirstOutside..<corners.count)
            edges.removeSubrange(cornerIndexFirstOutside..<corners.count)
        }
        corners.replaceSubrange(0...cornerIndexLastOutside, with: [intersectionFirst, intersectionLast])
        edges.replaceSubrange(0..<cornerIndexLastOutside, with: [edge])
    }

    internal static func nextIndex(_ index: Int, count: Int) -> Int {
        return index + 1 < count ? index + 1 : 0
    }

    internal static func prevIndex(_ index: Int, count: Int) -> Int {
        return (index > 0 ? index : count) - 1
    }
}

extension Spatial.Point3DFloat {
    func interpolate(to point: Point3DFloat, lerpFactor: Float) -> Point3DFloat {
        .init(vector: vector * (1.0 - lerpFactor) + point.vector * lerpFactor)
    }
}
