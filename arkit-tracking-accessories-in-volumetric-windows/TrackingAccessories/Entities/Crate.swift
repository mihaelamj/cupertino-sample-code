/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a wooden crate.
*/

import RealityKit

@MainActor
final class Crate: Entity, HasModel, HasCollision, HasPhysics {
    static private let entity = try! Entity.load(named: "Crate")
    
    required init() {
        super.init()

        var cratePhysics = PhysicsBodyComponent(massProperties: PhysicsMassProperties.default, mode: .static)
        cratePhysics.isAffectedByGravity = false
        
        children.replaceAll(Crate.entity.children)
        
        for cratePart in children {
            cratePart.generateCollisionShapes(recursive: false)
            cratePart.components.set(cratePhysics)
        }
    }
}
