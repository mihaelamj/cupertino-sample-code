/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents an orderly stack of cards.
*/

import SwiftUI
import TabletopKit
import RealityKit
import RealityKitContent

struct Stack: Equipment {
    let id: EquipmentIdentifier
    let initialState: BaseEquipmentState
    
    func layoutChildren(for snapshot: TableSnapshot, visualState: TableVisualState) -> EquipmentLayout {
        let children = snapshot.equipmentIDs(childrenOf: id)
        var poses: [EquipmentPose2D] = []
        poses.reserveCapacity(children.count)
        for child in children {
            poses.append(EquipmentPose2D(id: child, pose: .identity))
        }
        return .planarStacked(layout: poses)
    }

    init(index: EquipmentIdentifier, position: TableVisualState.Point2D) {
        id = index
        let approxSizeOfCard: Rect3D = .init(center: .zero, size: simd_float3(x: 0.1, y: 0, z: 0.15))
        initialState = State(parentID: .tableID,
                             seatControl: .restricted([]),
                             pose: .init(position: position, rotation: .zero),
                             boundingBox: approxSizeOfCard)
    }
}
