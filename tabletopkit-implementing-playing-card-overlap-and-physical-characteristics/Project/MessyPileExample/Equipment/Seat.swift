/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a seat.
*/

import SwiftUI
import TabletopKit

extension TableSeatIdentifier {
    static func seat(_ index: Int) -> Self { .init(index) }
}

struct Seat: TableSeat {
    let id: TableSeatIdentifier
    let initialState: TableSeatState

    init(index: Int = 0, position: TableVisualState.Point2D) {
        id = .seat(index)
        initialState = .init(pose: .init(position: position, rotation: .init()))
    }
}
