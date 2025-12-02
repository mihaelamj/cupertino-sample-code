/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a can.
*/

import RealityKit

@MainActor
final class Can: Entity, HasModel, HasCollision, HasPhysics {
    static private let entity = try! Entity.loadModel(named: "Can")
    
    required init(position: SIMD3<Float>) {
        super.init()
        
        self.position = position
        
        let canShapeResource = ShapeResource.generateConvex(from: Can.entity.model!.mesh)
        components.set(CollisionComponent(shapes: [canShapeResource]))
        components.set(GroundingShadowComponent(castsShadow: true))
        components.set(PhysicsBodyComponent(shapes: [canShapeResource],
                                            density: 10,
                                            material: .generate(friction: 0.4, restitution: 0.4),
                                            mode: .dynamic))
        model = Can.entity.model
    }
    
    required convenience init() {
        self.init(position: SIMD3(0, 0, 0))
    }
}
