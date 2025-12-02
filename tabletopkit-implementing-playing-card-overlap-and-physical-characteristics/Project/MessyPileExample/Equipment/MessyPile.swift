/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a pile of cards.
*/

import SwiftUI
import TabletopKit
import RealityKit
import RealityKitContent

struct MessyPile: EntityEquipment {
    let id: EquipmentIdentifier
    var entity: Entity
    let initialState: BaseEquipmentState

    func layoutChildren(for snapshot: TableSnapshot, visualState: TableVisualState) -> EquipmentLayout {
        let sortedChildrenIDs = snapshot.equipmentIDs(childrenOf: id)
        let boxes: [OrientedBox] = sortedChildrenIDs.map {
            let state = snapshot.state(matching: $0)!
            return .init(pose: state.pose, boundingBox: Rect3DFloat(state.boundingBox))
        }

        // Calculate an effective center of mass for each box,
        // accounting for the weight of supported boxes on top.
        let centersOfMass = CenterOfMassSolver().calculateCentersOfMass(boxes: boxes)

        var poses: [EquipmentPose3D] = []
        poses.reserveCapacity(sortedChildrenIDs.count)
        for (index, childID) in sortedChildrenIDs.enumerated() {
            // For each descendants, collect all possible supporting points of
            // previously placed descendants, and then find the support plane
            // underneath this box's center of mass.
            // The support plane is the upward-facing face of the convex
            // hull around the point cloud that intersects the vertical
            // line at the 2D center of mass.
            let box = boxes[index]
            if index == 0 {
                poses.append(EquipmentPose3D(id: childID, pose: makePose(pose2d: box.pose, boundingBox: box.boundingBox)))
                continue
            }
            let boundary = makeConvexBoundary2D(boundingBox: box.boundingBox, pose2d: box.pose)
            let convexHull = BoundedConvexHull(boundary: boundary)
            var countAdded = 0
            for indexPrev in 0..<index {
                let boxPrev = boxes[indexPrev]
                let posePrev = Pose3DFloat(poses[indexPrev].pose)
                let boundaryPrev = makeConvexBoundary2DOfTopPlane(boundingBox: boxPrev.boundingBox, pose: posePrev)
                let topPlane = makeTopPlane(boundingBox: boxPrev.boundingBox, pose: posePrev)
                if convexHull.addPlanarPolygon(polygon: boundaryPrev, plane: topPlane) {
                    countAdded += 1
                }
            }
            if countAdded == 0 {
                poses.append(EquipmentPose3D(id: childID, pose: makePose(pose2d: box.pose, boundingBox: box.boundingBox)))
                continue
            }
            let supportPlane = convexHull.findSupportPlane(at: centersOfMass[index])
            let pose = makePoseOnPlane(pose2d: box.pose, boundingBox: box.boundingBox, plane: supportPlane)
            poses.append(EquipmentPose3D(id: childID, pose: pose))
        }
        return .volumetric(layout: poses)
    }

    init(index: EquipmentIdentifier, position: TableVisualState.Point2D) {
        id = index
        
        entity = try! Entity.load(named: "centerPile_base", in: realityKitContentBundle)
        entity.scale *= 100
        entity.scale.y /= 10
        initialState = State(parentID: .tableID, seatControl: .restricted([]), pose: .init(position: position, rotation: .init()), entity: entity)
    }
}
