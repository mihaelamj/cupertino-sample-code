/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that contains methods for SceneKit scene rendering.
*/

import simd
import SceneKit

extension CubeRotation {

    func setupSceneKit() -> SCNScene {
        let scene = SCNScene()
  
        scene.background.contents = NSColor(red: 41 / 255,
                                            green: 42 / 255,
                                            blue: 48 / 255,
                                            alpha: 1)
        
        let lookAtNode = SCNNode()
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        cameraNode.camera = camera
        camera.fieldOfView = 25
        camera.usesOrthographicProjection = false
        cameraNode.position = SCNVector3(x: 2.5, y: 2.0, z: 5.0)
        let lookAt = SCNLookAtConstraint(target: lookAtNode)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [ lookAt ]
        
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: -1.5, y: 2.5, z: 1.5)
        
        light.type = .directional
        light.castsShadow = true
        light.shadowSampleCount = 8
        lightNode.constraints = [ lookAt ]
        
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NSColor(white: 0.5, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientNode)
        
        return scene
    }
    
    func addLineBetweenVertices(vertexA: simd_double3,
                                vertexB: simd_double3,
                                inScene scene: SCNScene,
                                color: NSColor = .yellow) {
        
        let geometrySource = SCNGeometrySource(vertices: [SCNVector3(x: vertexA.x,
                                                                     y: vertexA.y,
                                                                     z: vertexA.z),
                                                          SCNVector3(x: vertexB.x,
                                                                     y: vertexB.y,
                                                                     z: vertexB.z)])
        let indices: [Int8] = [0, 1]
        let indexData = Data(bytes: indices, count: 2)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .line,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int8>.size)
        
        let geometry = SCNGeometry(sources: [geometrySource],
                                   elements: [element])
        
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.emission.contents = color
        
        let node = SCNNode(geometry: geometry)
        
        scene.rootNode.addChildNode(node)
    }
    
    @discardableResult
    func addTriangle(vertices: [simd_double3], inScene scene: SCNScene) -> SCNNode {
        assert(vertices.count == 3, "vertices count must be 3")
        
        let vector1 = vertices[2] - vertices[1]
        let vector2 = vertices[0] - vertices[1]
        let normal = simd_normalize(simd_cross(vector1, vector2))
        
        let normalSource = SCNGeometrySource(normals: [SCNVector3(x: normal.x, y: normal.y, z: normal.z),
                                                       SCNVector3(x: normal.x, y: normal.y, z: normal.z),
                                                       SCNVector3(x: normal.x, y: normal.y, z: normal.z)])
        
        let sceneKitVertices = vertices.map {
            return SCNVector3(x: $0.x, y: $0.y, z: $0.z)
        }
        let geometrySource = SCNGeometrySource(vertices: sceneKitVertices)
        
        let indices: [Int8] = [0, 1, 2]
        let indexData = Data(bytes: indices, count: 3)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: 1,
                                         bytesPerIndex: MemoryLayout<Int8>.size)
        
        let geometry = SCNGeometry(sources: [geometrySource, normalSource],
                                   elements: [element])
        
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = NSColor.orange
        
        let node = SCNNode(geometry: geometry)
        
        scene.rootNode.addChildNode(node)
        
        return node
    }
    
    func addCube(vertices: [simd_double3], inScene scene: SCNScene) -> SCNNode {
        assert(vertices.count == 8, "vertices count must be 3")
        
        let sceneKitVertices = vertices.map {
            return SCNVector3(x: $0.x, y: $0.y, z: $0.z)
        }
        let geometrySource = SCNGeometrySource(vertices: sceneKitVertices)
        
        let indices: [Int8] = [
            // Bottom.
            0, 2, 1,
            1, 2, 3,
            // Back.
            2, 6, 3,
            3, 6, 7,
            // Left.
            0, 4, 2,
            2, 4, 6,
            // Right.
            1, 3, 5,
            3, 7, 5,
            // Front.
            0, 1, 4,
            1, 5, 4,
            // Top.
            4, 5, 6,
            5, 7, 6 ]
        
        let indexData = Data(bytes: indices, count: indices.count)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: 12,
                                         bytesPerIndex: MemoryLayout<Int8>.size)
        
        let geometry = SCNGeometry(sources: [geometrySource],
                                   elements: [element])
        
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.diffuse.contents = NSColor.systemMint
        geometry.firstMaterial?.metalness.contents = 0.2
        geometry.firstMaterial?.lightingModel = .physicallyBased
        
        let node = SCNNode(geometry: geometry)
        
        scene.rootNode.addChildNode(node)
        
        return node
    }
    
    @discardableResult
    func addSphereAt(position: simd_double3,
                     radius: CGFloat = 0.1,
                     color: NSColor,
                     scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere(radius: radius)
        sphere.firstMaterial?.diffuse.contents = color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = simd_float(position)
        scene.rootNode.addChildNode(sphereNode)
        
        return sphereNode
    }
}
