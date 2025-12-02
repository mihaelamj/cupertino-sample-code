/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Project utilities that contain various 2D geometry types.
*/

import Spatial
import TabletopKit

// The TabletopKit 2D plane of interest is X,Z (where Y is up).

// MARK: - Angle2DFloat helpers for 2D

extension Spatial.Angle2DFloat {
    var yRotatedAxes: (x: Vector3DFloat, z: Vector3DFloat) {
        let sin: Float = sin(radians)
        let cos: Float = cos(radians)
        return (x: .init(x: cos, y: 0, z: -sin), z: .init(x: sin, y: 0, z: cos))
    }
}

// MARK: - Vector3DFloat helpers for 2D

extension Spatial.Vector3DFloat {
    init(projecting point3d: Vector3DFloat) {
        self.init(x: point3d.x, y: 0, z: point3d.z)
    }
}

extension Spatial.Vector3DFloat {
    func rotated2D(by angle: Angle2DFloat) -> Vector3DFloat {
        let axes = angle.yRotatedAxes
        return .init(x: x * axes.x.x + z * axes.z.x, y: y, z: x * axes.x.z + z * axes.z.z)
    }

    func inverseRotated2D(by angle: Angle2DFloat) -> Vector3DFloat {
        let axes = angle.yRotatedAxes
        return .init(x: simd_dot(self.vector, axes.x.vector), y: y, z: simd_dot(self.vector, axes.z.vector))
    }
}

// MARK: - Point3DFloat helpers for 2D

extension Spatial.Point3DFloat {
    init(_ point2d: TableVisualState.Point2D) {
        self.init(x: point2d.x, y: 0, z: point2d.z)
    }

    init(projecting point3d: Point3DFloat) {
        self.init(x: point3d.x, y: 0, z: point3d.z)
    }

    func deproject(height: Float) -> Point3DFloat {
        return .init(x: x, y: height, z: z)
    }
}

extension Spatial.Point3DFloat {
    func applying(_ pose: TableVisualState.Pose2D) -> Point3DFloat {
        return Point3DFloat(pose.position) + Vector3DFloat(self).rotated2D(by: Angle2DFloat(pose.rotation))
    }

    func unapplying(_ pose: TableVisualState.Pose2D) -> Point3DFloat {
        return Point3DFloat((self - Point3DFloat(pose.position)).inverseRotated2D(by: Angle2DFloat(pose.rotation)))
    }
}

// MARK: - Rect3DFloat helpers for 2D

extension Spatial.Rect3DFloat {
    init(projecting rect3d: Rect3DFloat) {
        self.init(origin: Point3DFloat(projecting: rect3d.origin), size: Size3DFloat(Vector3DFloat(projecting: Vector3DFloat(rect3d.size))))
    }

    // Detect the overlap of nonzero area in 2D X and Z directions.
    func overlaps2D(_ rect: Rect3DFloat) -> Bool {
        rect.max.x > min.x && rect.max.z > min.z && rect.min.x < max.x && rect.min.z < max.z
    }
}

extension Spatial.Rect3DFloat {
    func nearAndFarCorner(dir: Vector3DFloat) -> (near: Point3DFloat, far: Point3DFloat) {
        let maskGt0: simd_int3 = [dir.x > 0 ? -1 : 0, dir.y > 0 ? -1 : 0, dir.z > 0 ? -1 : 0]
        let near = Point3DFloat(vector: simd_select(max.vector, min.vector, maskGt0))
        let far = Point3DFloat(vector: simd_select(min.vector, max.vector, maskGt0))
        return (near: near, far: far)
    }

    // Returns the bounding rectangle, in coordinate space, rotated around Y,
    // by the rotation parameter, that exactly contains this rectangle.
    func inverseRotated2D(by rotation: Angle2DFloat) -> Rect3DFloat {
        let axes = rotation.yRotatedAxes
        let cornersX = nearAndFarCorner(dir: axes.x)
        let cornersZ = nearAndFarCorner(dir: axes.z)
        let min = Vector3DFloat(x: simd_dot(cornersX.near.vector, axes.x.vector), y: max.y, z: simd_dot(cornersZ.near.vector, axes.z.vector))
        let max = Vector3DFloat(x: simd_dot(cornersX.far.vector, axes.x.vector), y: min.y, z: simd_dot(cornersZ.far.vector, axes.z.vector))
        return Rect3DFloat(origin: min, size: max - min)
    }

    // Returns the bounding rectangle that exactly contains this rectangle
    // rotated, around Y, by the rotation parameter.
    func rotated2D(by rotation: Angle2DFloat) -> Rect3DFloat {
        return inverseRotated2D(by: -rotation)
    }
}

// MARK: - OrientedRect2DFloat

struct OrientedRect2DFloat {
    let rect: Rect3DFloat
    let position: Point3DFloat
    let rotation: Angle2DFloat
}

extension OrientedRect2DFloat {
    init(rect: Rect3DFloat, pose: TableVisualState.Pose2D) {
        self.rect = rect
        self.position = Point3DFloat(pose.position)
        self.rotation = Angle2DFloat(pose.rotation)
    }
}

extension OrientedRect2DFloat {
    func overlaps(_ other: OrientedRect2DFloat) -> Bool {
        let translateToOther = other.position - position
        let rotateToOther = other.rotation - rotation
        
        // Calculate the local axis aligned rectangle that contains
        // `other.rect` transformed to local space.
        let otherPositionLS = translateToOther.inverseRotated2D(by: rotation)
        let otherRectLS = other.rect.rotated2D(by: rotateToOther).translated(by: otherPositionLS)
        
        // Test if any edge of rectangle is a separating plane.
        if !rect.overlaps2D(otherRectLS) {
            return false
        }
        
        // Calculate the other axis-aligned rectangle that contains
        // `rect`, transformed to other local space.
        let positionOS = (translateToOther * -1).inverseRotated2D(by: other.rotation)
        let rectOS = rect.rotated2D(by: rotateToOther).translated(by: positionOS)
        
        // Test if any edge of the other rectangle is a separating plane.
        return other.rect.overlaps2D(rectOS)
    }
}
