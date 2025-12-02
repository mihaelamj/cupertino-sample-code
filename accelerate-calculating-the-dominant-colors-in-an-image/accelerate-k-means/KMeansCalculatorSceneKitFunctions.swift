/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Functions that manage the SceneKit point cloud that represents colors in the image.
*/


import SceneKit

extension KMeansCalculator {
    
    /// Creates a SceneKit point cloud in three dimensions that correspond to the red, green, and blue
    /// pixels in the source image.
    func populateHistogramPointCloud() {
        
        for node in scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        centroidNodes.removeAll()
        
        let vertexCount = dimension * dimension
        
        let vertices = (0 ..< vertexCount).map { i in
            SCNVector3(x: CGFloat(saturate(redStorage[i])),
                       y: CGFloat(saturate(greenStorage[i])),
                       z: CGFloat(saturate(blueStorage[i])))
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        let colorsData = makePointColors(vertices: vertices)
        let colorSource = SCNGeometrySource(data: colorsData,
                                            semantic: .color,
                                            vectorCount: vertexCount,
                                            usesFloatComponents: true,
                                            componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<UInt8>.stride,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<UInt8>.stride * 4)

        let pointCloudElement = SCNGeometryElement(indices: ( 0 ..< vertexCount).map { Int32($0) },
                                                   primitiveType: .point)
        pointCloudElement.pointSize = 2
        pointCloudElement.minimumPointScreenSpaceRadius = 1
        pointCloudElement.maximumPointScreenSpaceRadius = 4
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource],
                                   elements: [pointCloudElement])
        
        let material = SCNMaterial()
        material.lightingModel = .constant
        geometry.materials = [material]
        
        let pointCloudNode = SCNNode()
        pointCloudNode.geometry = geometry
        scene.rootNode.addChildNode(pointCloudNode)
        
        scene.background.contents = NSColor.gray
        
        addCentroidsToScene()
        addAxesToScene()
        addDummyCubeToScene()
    }
    
    func makePointColors(vertices: [SCNVector3]) -> Data {
        let colorsBufferLength = vertices.count * 4
        let colors = [UInt8](unsafeUninitializedCapacity: colorsBufferLength) {
            buffer, initializedCount in
            
            var i = 0
            for vertex in vertices {
                buffer[i] = UInt8(vertex.x * 255)
                buffer[i + 1] = UInt8(vertex.y * 255)
                buffer[i + 2] = UInt8(vertex.z * 255)
                buffer[i + 3] = 192
                i += 4
                
            }
            initializedCount = colorsBufferLength
        }
        
        return Data(colors)
    }
    
    /// Adds an invisible cube to ensure the entire point cloud node is visible.
    func addDummyCubeToScene() {
        let cube = SCNBox(width: 1.2, height: 1.2, length: 1.2, chamferRadius: 0)
        let node = SCNNode(geometry: cube)
        node.position = .init(x: 0.5, y: 0.5, z: 0.5)
        node.opacity = 0
        scene.rootNode.addChildNode(node)
    }
    
    func addCentroidsToScene() {
        for _ in 0 ..< k {
            let sphere = SCNSphere(radius: 0.02)
            let centroidNode = SCNNode(geometry: sphere)
            centroidNodes.append(centroidNode)
            scene.rootNode.addChildNode(centroidNode)
        }
    }
    
    func addAxesToScene() {
        func addAxisCube(x: CGFloat, y: CGFloat, z: CGFloat) {
            let cube = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            cube.materials.first!.diffuse.contents = NSColor(red: x, green: y, blue: z, alpha: 1)
            cube.materials.first!.lightingModel = .constant
            let node = SCNNode(geometry: cube)
            node.position = SCNVector3(x: x, y: y, z: z)
            scene.rootNode.addChildNode(node)
        }
        
        // Add axes to SceneKit view.
        for i in stride(from: 0, through: 1, by: 0.01) {
            addAxisCube(x: i, y: 0, z: 0)
            addAxisCube(x: 0, y: i, z: 0)
            addAxisCube(x: 0, y: 0, z: i)
            
            addAxisCube(x: i, y: 1, z: 0)
            addAxisCube(x: 0, y: 1, z: i)
            addAxisCube(x: 1, y: i, z: 1)
        
            addAxisCube(x: 1, y: i, z: 0)
            addAxisCube(x: 1, y: 0, z: i)
            addAxisCube(x: i, y: 1, z: 1)
            
            addAxisCube(x: 0, y: i, z: 1)
            addAxisCube(x: i, y: 0, z: 1)
            addAxisCube(x: 1, y: 1, z: i)
        }
    }
    
    /// Updates the centroid SceneKit nodes.
    func updateCentroidNodes() {
        for centroid in centroids.enumerated() {
            
            let red = CGFloat(saturate(centroid.element.red))
            let green = CGFloat(saturate(centroid.element.green))
            let blue = CGFloat(saturate(centroid.element.blue))
            
            let node = centroidNodes[centroid.offset]
            
            node.position = .init(x: red,
                                  y: green,
                                  z: blue)
            
            node.geometry?.firstMaterial?.diffuse.contents = NSColor(red: red,
                                                                     green: green,
                                                                     blue: blue,
                                                                     alpha: 1.0)
        }
    }
}
