/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that visualizes the player's gesture input.
*/

import RealityKit

struct InputVisualizerSystem: System {
    let query = EntityQuery(where: .has(InputVisualizerComponent.self))
     
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        for visualizerEntity in context.entities(matching: query, updatingSystemWhen: .rendering) {
            guard let visualizerComponent = visualizerEntity.components[InputVisualizerComponent.self],
                  let movementComponent = visualizerComponent.character.components[CharacterMovementComponent.self],
                  let physicsRoot = PhysicsSimulationComponent.nearestSimulationEntity(for: visualizerEntity) else {
                continue
            }
            // Set the position and direction of the direction indicator entity.
            let moveDirection = physicsRoot.convert(direction: movementComponent.inputMoveDirection, from: nil) * physicsRoot.scale.x
            let visualizerPosition = if visualizerComponent.useRelativeDragInput {
                visualizerComponent.character.position + moveDirection * visualizerComponent.directionIndicatorRadius
            } else {
                visualizerComponent.character.position + physicsRoot.convert(direction: movementComponent.dragDelta, from: nil)
            }
            visualizerComponent.directionIndicator.look(at: visualizerComponent.character.position,
                                                        from: visualizerPosition,
                                                        relativeTo: physicsRoot)
            
            // Update the direction indicator's blend shape animation to animate it from a sphere to a cone.
            let dragPercent = remap(value: length(moveDirection), fromRange: 0...1)
            visualizerComponent.directionIndicator.components[BlendShapeWeightsComponent.self]?.weightSet[0].weights[0] = 1 - dragPercent
            visualizerComponent.directionIndicator.isEnabled = visualizerComponent.isDragActive
            
            // Update the jump indicator visual.
            if let targetPosition = movementComponent.targetJumpPosition {
                visualizerComponent.jumpIndicator.setPosition(targetPosition, relativeTo: physicsRoot)
                visualizerComponent.jumpIndicator.isEnabled = true
            } else {
                visualizerComponent.jumpIndicator.isEnabled = false
            }
        }
    }
}
