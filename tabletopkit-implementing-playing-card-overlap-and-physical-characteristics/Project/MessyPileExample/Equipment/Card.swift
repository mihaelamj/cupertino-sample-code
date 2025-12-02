/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a card.
*/

import SwiftUI
import TabletopKit
import RealityKit
import RealityKitContent

struct Card: EntityEquipment {
    typealias State = CardState

    let id: EquipmentIdentifier
    var entity: Entity
    var initialState: State

    func restingOrientation(state: State) -> Rotation3D {
        state.faceUp ? .identity : .init(angle: .init(degrees: +180), axis: .init(x: 0, y: 0, z: 1))
    }

    init(index: Int = 0, position: TableVisualState.Point2D, parent: EquipmentIdentifier) {
        id = EquipmentIdentifier(index)
        entity = try! Entity.load(named: "card", in: realityKitContentBundle)
        entity.scale *= 100
        entity.scale.y *= 0.25
        initialState = .init(faceUp: false, parentID: parent, pose: .init(position: position, rotation: .init()), entity: entity)
    }
}
