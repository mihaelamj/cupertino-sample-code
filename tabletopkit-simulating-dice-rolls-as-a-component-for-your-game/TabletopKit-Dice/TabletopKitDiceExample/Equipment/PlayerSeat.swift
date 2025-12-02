/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a seat.
*/
import SwiftUI
import RealityKit
import TabletopKit
import RealityKitContent

struct PlayerSeat: TableSeat {
    let id: TableSeatIdentifier
    let initialState: TableSeatState

    init(index: Int, position: TableVisualState.Point2D, rotation: Angle2D) {
        id = .init(index)
        initialState = .init(pose: .init(position: position, rotation: rotation))
    }
}
