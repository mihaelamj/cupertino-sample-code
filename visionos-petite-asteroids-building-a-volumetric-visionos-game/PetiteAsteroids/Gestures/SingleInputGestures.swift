/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of gestures that make up the single input mode.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct SingleInputJumpGesture: Gesture {
    @Environment(AppModel.self) private var appModel
    
    var body: some Gesture {
        SpatialTapGesture()
            // Only target this gesture to entities with the custom component.
            .targetedToEntity(where: .has(LevelInputTargetComponent.self))
             // The character jumps when the gesture ends.
            .onEnded() { event in
                // Guard for the character's container entity.
                guard let containerEntity = appModel.character.parent else { return }
                
                // Convert the tap position to scene space.
                var targetPosition = event.convert(event.location3D, from: .local, to: .scene)
                
                // Next, convert the scene-space position to one in the character's container entity space.
                targetPosition = containerEntity.convert(position: targetPosition, from: nil)

                // Pass the jump target position to a custom component for this game.
                appModel.character.components[CharacterMovementComponent.self]?.targetJumpPosition = targetPosition
                
                // Reset the jump buffer timer, which helps the game feel more responsive when players try to jump a few frames before hitting the
                // ground.
                appModel.character.components[CharacterMovementComponent.self]?.jumpBufferTimer = GameSettings.jumpBufferTime
            }
    }
}

struct SingleInputFloorJumpGesture: Gesture {
    @Environment(AppModel.self) private var appModel
    
    var body: some Gesture {
        SpatialTapGesture()
            .targetedToEntity(appModel.floorInputTarget)
            .onEnded() { event in
                // Ray cast from an estimate of the player position to the interaction position to determine the target jump position.
                let interactionPosition = event.convert(event.location3D, from: .local, to: .scene)
                let playerPositionEstimate: SIMD3<Float> = [0, 0, 2.5]
                if let hit = appModel.root.scene?.raycast(origin: playerPositionEstimate,
                                                          direction: interactionPosition - playerPositionEstimate,
                                                          length: 5,
                                                          query: .nearest,
                                                          mask: GameCollisionGroup.shadowReceiver.collisionGroup).first {
                    let targetJumpPosition = appModel.character.parent?.convert(position: hit.position, from: nil)
                    appModel.character.components[CharacterMovementComponent.self]?.targetJumpPosition = targetJumpPosition
                    appModel.character.components[CharacterMovementComponent.self]?.jumpBufferTimer = GameSettings.jumpBufferTime
                }
            }
    }
}

struct SingleInputDragGesture: Gesture {
    @Environment(AppModel.self) private var appModel
    
    var isDragActive: GestureState<Bool>
    @State private var dragStartPosition: SIMD3<Float> = .zero
    @State private var isDragging = false
    
    var body: some Gesture {
        DragGesture(minimumDistance: CGFloat(GameSettings.dragMinimumDistance), coordinateSpace: .local)
            .targetedToAnyEntity()
            .updating(isDragActive) { value, state, transaction in
                state = true
            }
            .onChanged() { event in
                // Guard for the nearest physics simulation entity.
                guard let physicsRoot = PhysicsSimulationComponent.nearestSimulationEntity(for: appModel.character) else { return }
                
                // Get the drag position in scene space.
                let dragPosition = event.convert(event.location3D, from: .local, to: .scene)
                        
                // Start the drag if the player isn't already dragging.
                if !isDragging {
                    dragStartPosition = dragPosition
                    isDragging = true
                }

                // Update the scene-space, drag-start position.
                dragStartPosition = updateDragStartPosition(
                    dragStartPosition: dragStartPosition,
                    dragPosition: dragPosition,
                    physicsRoot: physicsRoot,
                    useRelativeDragInput: appModel.rollInputMode == .relative
                )
                
                let sceneDragDelta = dragPosition - dragStartPosition
                // Normalize the scene-space drag translation and pass it to the character movement component.
                let normalizedSceneDragDelta = sceneDragDelta == .zero ? .zero : simd_normalize(sceneDragDelta)
                let inputDirection = normalizedSceneDragDelta * (min(length(sceneDragDelta), GameSettings.dragRadius) / GameSettings.dragRadius)
                appModel.character.components[CharacterMovementComponent.self]?.inputMoveDirection = inputDirection
                appModel.character.components[CharacterMovementComponent.self]?.dragDelta = sceneDragDelta
            }
            .onEnded() { event in
                isDragging = false
            }
    }
}
