/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Project utility functions.
*/
import RealityKit

func addShadowRecursive(entity: Entity) {
    if let entity = entity as? ModelEntity {
        entity.components.set(GroundingShadowComponent(castsShadow: true, receivesShadow: true))
    }

    for child in entity.children {
        addShadowRecursive(entity: child)
    }
}
