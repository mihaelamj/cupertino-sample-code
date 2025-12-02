/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure for calculating the adjusted centers of mass of a set of
  overlapping planar equipment to account for leverage from above.
*/

import Spatial
import TabletopKit

struct OrientedBox {
    let pose: TableVisualState.Pose2D
    let boundingBox: Rect3DFloat
}

extension OrientedRect2DFloat {
    init(_ box: OrientedBox) {
        rect = box.boundingBox
        rotation = .init(box.pose.rotation)
        position = .init(box.pose.position)
    }
}

struct CenterOfMassSolver {
    let insetFraction: Float
    let partialWeight: Float

    init(minInsetFraction: Float = 0.1, partialSupportWeight: Float = 0.3) {
        insetFraction = minInsetFraction
        partialWeight = partialSupportWeight
    }

    static func calculateCenterOfMass(_ box: OrientedBox) -> Point3DFloat {
        let center2d = Point3DFloat(projecting: box.boundingBox.center)
        return center2d.applying(box.pose)
    }
    
    static func clampCenterOfMass(_ center: Point3DFloat,
                                  to box: OrientedBox,
                                  inset: Float = 0) -> Point3DFloat {
        let rectInset = Vector3DFloat(projecting: .init(box.boundingBox.size)) * inset
        let rect2d = Rect3DFloat(projecting: box.boundingBox)
        let clampToRect2d = Rect3DFloat(origin: rect2d.origin + rectInset, size: rect2d.size - rectInset * 2)
        let rotation = Angle2DFloat(box.pose.rotation)
        let centerLS = (center - Point3DFloat(box.pose.position)).inverseRotated2D(by: rotation)
        let clampedCenterLS = Point3DFloat(vector: clamp(centerLS.vector, min: clampToRect2d.min.vector, max: clampToRect2d.max.vector))
        return Point3DFloat(box.pose.position) + Vector3DFloat(clampedCenterLS).rotated2D(by: rotation)
    }

    func calculateCenterOfContactAndWeight(of box: OrientedBox,
                                           on boxBase: OrientedBox) -> (center: Point3DFloat, weight: Float) {
        let center = CenterOfMassSolver.calculateCenterOfMass(box)
        let rectBase = OrientedRect2DFloat(boxBase)
        let centerLS = Point3DFloat((center - rectBase.position).inverseRotated2D(by: rectBase.rotation))
        let clampedCenterLS = Point3DFloat(vector: clamp(centerLS.vector, min: rectBase.rect.min.vector, max: rectBase.rect.max.vector))
        
        let distanceToNearest = (centerLS - clampedCenterLS).length
        if distanceToNearest == 0 {
            // If the center of mass of box is inside the outline of `boxBase`,
            // apply the full weight at that point.
            return (center: center, weight: 1.0)
        }
        
        // If the center of mass of `box` is outside the outline of `boxBase`,
        // apply a fraction of the weight at the nearest edge, assuming that
        // the rest of the weight will fall on other supports.
        //
        // In reality, a box distributes its weight between multiple supporting
        // contact points that depend on the distance to each.
        //
        // Since you haven't determined the contact points in detail, apply a
        // fixed fraction of the weight to all possibly contacted boxes that
        // this box might be in contact with.
        return (center: clampedCenterLS, weight: partialWeight)
    }
    
    func calculateCentersOfMass(boxes: [OrientedBox]) -> [Point3DFloat] {
        if boxes.isEmpty {
            return []
        }
        if boxes.count == 1 {
            return [CenterOfMassSolver.calculateCenterOfMass(boxes[0])]
        }
        
        var centers: [Point3DFloat] = []
        centers.reserveCapacity(boxes.count)
        for (index, box) in boxes.enumerated() {
            
            // Calculate the average center of mass of this box, and all boxes
            // that are stacked atop it, recursively.
            //
            // The sample assumes that a box that is stacked atop is to rest
            // all or part of its weight on the base depending on whether its
            // center lies inside the base box's area.
            let orientedBox = OrientedRect2DFloat(box)
            var center = CenterOfMassSolver.calculateCenterOfMass(box)
            var weightedOffset = Vector3DFloat.zero
            var totalWeight: Float = 0
            for indexNext in (index + 1)..<boxes.count {
                
                let boxNext = boxes[indexNext]
                let orientedBoxNext = OrientedRect2DFloat(boxNext)
                if !orientedBox.overlaps(orientedBoxNext) {
                    // Other boxes that don't directly overlap, but sit atop a
                    // box that overlaps, or a chain of such indirect overlaps,
                    // might also apply a fraction of their weight at some
                    // contact point.
                    // However, indirect overlaps contribute exponentially less
                    // and are increasingly likely to be spurious as the count
                    // of links in the chain increases, so it's simpler and
                    // reasonably accurate to just ignore them.
                    continue
                }
                
                // Each box applies its weight at its own center and clamps to the
                // base box rectangle. This becomes inaccurate if the actual
                // average point of contact isn't near the center of this box,
                // and can produce nonphysical forces when it lies on the
                // opposite side of the base box's center.
                //
                // In theory, a more sophisticated analysis of the stacking
                // heights, and overlap regions, of the 2D rectangles could
                // produce better guesses at the likely contact points, and
                // fewer cases with non-physical forces applied.
                let contact = calculateCenterOfContactAndWeight(of: boxNext, on: box)
                weightedOffset += Vector3DFloat(contact.center) * contact.weight
                totalWeight += contact.weight
            }
            
            if totalWeight > 0 {
                center = (center + weightedOffset) / (1.0 + totalWeight)
                // Clamp to a fractional inset area of the base box's area.
                center = CenterOfMassSolver.clampCenterOfMass(center, to: box, inset: insetFraction)
            }
            centers.append(center)
        }
        return centers
    }
}
