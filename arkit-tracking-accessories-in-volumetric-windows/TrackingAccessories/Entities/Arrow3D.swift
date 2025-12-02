/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A 3D arrow.
*/

import RealityKit

@MainActor
class Arrow3D: Entity, HasModel {
    static private let shaftLength: Float = 1.0
    static private let arrowheadLength = Arrow3D.shaftLength / 10
            
    required init() {
        super.init()
        let material = SimpleMaterial(color: .green, isMetallic: false)
        
        // Create a 3D arrow from a cylinder and a cone.
        let shaft = ModelEntity(mesh: MeshResource.generateCylinder(height: Arrow3D.shaftLength,
                                                                    radius: Arrow3D.shaftLength / 100),
                                materials: [material])
        addChild(shaft)
        
        // The bottom of the shaft needs to start at the origin.
        shaft.position.y = Arrow3D.shaftLength / 2
        
        let arrowHead = ModelEntity(mesh: MeshResource.generateCone(height: Arrow3D.arrowheadLength,
                                                                    radius: Arrow3D.shaftLength / 20),
                                    materials: [material])
        addChild(arrowHead)
        
        // The bottom of the arrowhead needs to be flush with the top of the shaft.
        arrowHead.position.y = Arrow3D.shaftLength + Arrow3D.arrowheadLength / 2
    }
}
