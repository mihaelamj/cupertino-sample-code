/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a ball.
*/

import RealityKit

@MainActor
final class Ball: Entity, HasModel, HasCollision, HasPhysics {
    static private let entity = try! Entity.loadModel(named: "TennisBall")
    
    static private let radius: Float = 0.05
    
    static private let physicsBodyComponent = PhysicsBodyComponent(shapes: [.generateSphere(radius: Ball.radius)],
                                                                   density: 100,
                                                                   material: .generate(friction: 0.4, restitution: 0.4),
                                                                   mode: .dynamic)
    let velocityVisualization = Arrow3D()

    required init() {
        super.init()

        self.model = Ball.entity.model
        components.set(CollisionComponent(shapes: [.generateSphere(radius: Ball.radius)]))
        components.set(GroundingShadowComponent(castsShadow: true))
        velocityVisualization.isEnabled = false
        addChild(velocityVisualization)
    }
    
    func enablePhysics(linearVelocity: SIMD3<Float>, angularVelocity: SIMD3<Float> = [0.0, 0.0, 0.0]) {
        self.physicsBody = Ball.physicsBodyComponent
        self.physicsMotion = PhysicsMotionComponent(linearVelocity: linearVelocity, angularVelocity: angularVelocity)
    }
    
    func disablePhysics() {
        physicsBody = nil
        physicsMotion = nil
    }
}
