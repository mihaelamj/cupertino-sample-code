/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility method for handling input gestures.
*/

import RealityKit

@MainActor
/// Updates the drag start position so that it remains coplanar with current drag position.
func updateDragStartPosition(dragStartPosition: SIMD3<Float>,
                             dragPosition: SIMD3<Float>,
                             physicsRoot: Entity,
                             useRelativeDragInput: Bool) -> SIMD3<Float> {
    // Convert the drag start and current position to the local space of the physics root.
    let dragPositionInPhysicsSpace = physicsRoot.convert(position: dragPosition, from: nil)
    var dragStartPositionInPhysicsSpace = physicsRoot.convert(position: dragStartPosition, from: nil)
    // Project the drag start position to an XZ-plane that's parallel to the current drag position.
    dragStartPositionInPhysicsSpace.y = dragPositionInPhysicsSpace.y
    // Get the drag translation in the XZ-plane of the local space of the physics root.
    let dragDelta = (dragPositionInPhysicsSpace - dragStartPositionInPhysicsSpace)

    // When `useRelativeDragInput` is true, the drag start point will follow behind the current drag position.
    let dragDistance = length(dragDelta)
    let dragRadius = GameSettings.dragRadius / GameSettings.scale
    if useRelativeDragInput && dragDistance > dragRadius {
        // Move the drag start position so that it follows behind the current drag position so the player doesn't have to move their
        // input device all the way back to change direction.
        let normalizedDragDelta = dragDelta / dragDistance
        dragStartPositionInPhysicsSpace = dragPositionInPhysicsSpace - normalizedDragDelta * dragRadius
    }

    // Update the scene-space, drag-start position.
    return physicsRoot.convert(position: dragStartPositionInPhysicsSpace, to: nil)
}
