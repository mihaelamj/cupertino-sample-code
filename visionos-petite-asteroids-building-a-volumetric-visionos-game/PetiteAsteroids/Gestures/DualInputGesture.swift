/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A gesture for the dual input mode.
*/

import SwiftUI
import RealityKit

struct DualInputGesture: Gesture {
    enum SpatialEventClassification {
        case pinch
        case drag
        case unresolved
    }
    
    struct SpatialEventState {
        var classification: SpatialEventClassification = .unresolved
        var chirality: Chirality
        var startPosition: SIMD3<Float>
        var translation: SIMD3<Float> = .zero
        var startTime: TimeInterval
        var duration: TimeInterval = 0
    }
    
    @Environment(AppModel.self) private var appModel
    
    var isDragActive: GestureState<Bool>
    @State var activeSpatialEvents: [SpatialEventCollection.Event.ID: SpatialEventState] = [:]
    
    private func handleSpatialEventEnded(spatialEvent: SpatialEventState?) {
        if spatialEvent?.classification == .unresolved {
            appModel.character.components[CharacterMovementComponent.self]?.jumpBufferTimer = GameSettings.jumpBufferTime
        }
    }

    private func updateActiveSpatialEvents(event: EntityTargetValue<SpatialEventGesture.Value>) {
        // Guard for the nearest physics simulation entity.
        guard let physicsRoot = PhysicsSimulationComponent.nearestSimulationEntity(for: appModel.character) else { return }

        for value in event.gestureValue {
            // Skip spatial events without chirality.
            guard let chirality = value.chirality else {
                continue
            }
            
            // Get the event position in scene space.
            let spatialEventPosition = event.convert(value.location3D, from: .local, to: .scene)
            
            // Handle and remove the event if it ended.
            if value.phase == .ended {
                handleSpatialEventEnded(spatialEvent: activeSpatialEvents[value.id])
                activeSpatialEvents[value.id] = nil
            // Update the event state if it's already active.
            } else if var activeSpatialEvent = activeSpatialEvents[value.id] {
                // Update the scene-space, event-start position.
                activeSpatialEvent.startPosition = updateDragStartPosition(
                    dragStartPosition: activeSpatialEvent.startPosition,
                    dragPosition: spatialEventPosition,
                    physicsRoot: physicsRoot,
                    useRelativeDragInput: appModel.rollInputMode == .relative
                )
                // Update the scene-space event translation.
                activeSpatialEvent.translation = spatialEventPosition - activeSpatialEvent.startPosition
                activeSpatialEvent.duration = value.timestamp - activeSpatialEvent.startTime
                activeSpatialEvents[value.id] = activeSpatialEvent
            // Otherwise, create a new state structure to track this event.
            } else {
                // Add the event to the dictionary of active spatial events.
                let spatialEventState = SpatialEventState(chirality: chirality,
                                                          startPosition: spatialEventPosition,
                                                          startTime: value.timestamp)
                activeSpatialEvents[value.id] = spatialEventState
            }
        }
    }
    
    private func classifyUnresolvedSpatialEvents() {
        for (spatialEventId, spatialEvent) in activeSpatialEvents where spatialEvent.classification == .unresolved {
            // Classify the event as a pinch if there's already an active drag event.
            if activeSpatialEvents.values.contains(where: { $0.classification == .drag }) {
                activeSpatialEvents[spatialEventId]?.classification = .pinch
            // Classify the event as a drag if there's already an active pinch event
            // or the length of event's translation is larger than the drag minimum distance.
            } else if activeSpatialEvents.values.contains(where: { $0.classification == .pinch }) ||
                        length_squared(spatialEvent.translation) > GameSettings.dragMinimumDistance {
                activeSpatialEvents[spatialEventId]?.classification = .drag
            }
        }
    }
    
    private func respondToActiveSpatialEvents() {
        for spatialEvent in activeSpatialEvents.values {
            switch spatialEvent.classification {
                case .drag:
                    // Move the character in the direction of the spatial event translation.
                    var inputDirection = spatialEvent.translation / GameSettings.dragRadius
                    let inputDirectionMagnitude = length(inputDirection)
                    if inputDirectionMagnitude > 1 {
                        inputDirection /= inputDirectionMagnitude
                    }
                    appModel.character
                        .components[CharacterMovementComponent.self]?.inputMoveDirection = inputDirection
                    appModel.character
                        .components[CharacterMovementComponent.self]?.dragDelta = spatialEvent.translation
                case .pinch:
                    // Make the character jump if the player pinched this frame.
                    if spatialEvent.duration == 0 {
                        appModel.character.components[CharacterMovementComponent.self]?.jumpBufferTimer = GameSettings.jumpBufferTime
                    }
                default:
                    break
            }
        }
    }
    
    var body: some Gesture {
        SpatialEventGesture()
            .targetedToAnyEntity()
            .updating(isDragActive) { value, state, transaction in
                state = activeSpatialEvents.values.contains(where: { $0.classification == .drag })
            }
            .onChanged() { event in
                // Update the active spatial events.
                updateActiveSpatialEvents(event: event)
                
                // Classify unresolved spatial events.
                classifyUnresolvedSpatialEvents()
                
                // Respond to the active spatial events.
                respondToActiveSpatialEvents()
            }.onEnded() { event in
                // Handle and remove any events that ended.
                for value in event.gestureValue {
                    if value.phase == .ended {
                        handleSpatialEventEnded(spatialEvent: activeSpatialEvents[value.id])
                    }
                    activeSpatialEvents[value.id] = nil
                }
            }
    }
}
