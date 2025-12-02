/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component to set the hiker drag state.
*/

import RealityKit

struct HikerDragStateComponent: Component {
    enum DragState {
        case slider
        case entity
        case none
    }

    var dragState: DragState = .none
}
