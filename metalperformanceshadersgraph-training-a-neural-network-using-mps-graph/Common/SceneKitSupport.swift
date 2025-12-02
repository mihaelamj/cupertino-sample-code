/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Class containing methods for SceneKit scene rendering
*/

import UIKit
import simd
import SceneKit

class ProgressCube {
    var outerCube: SCNNode
    var innerCube: SCNNode
    
    var size: Float
    var delta: Float
    
    init(outerSize: Float, delta: Float) {
        self.size = outerSize
        self.delta = delta
        let outerCubePosition = [0.0, 0.0, 0.0]
        
        let cgOuterSize = CGFloat(outerSize)

        let outerGeometry = SCNBox(width: cgOuterSize,
                                   height: cgOuterSize,
                                   length: cgOuterSize,
                                   chamferRadius: 0.1)

        outerGeometry.firstMaterial?.isDoubleSided = true
        outerGeometry.firstMaterial?.transparency = CGFloat(0.5)
        outerGeometry.firstMaterial?.diffuse.contents = UIColor.gray
        outerGeometry.firstMaterial?.lightingModel = .physicallyBased
        
        outerCube = SCNNode(geometry: outerGeometry)
        outerCube.position = SCNVector3(outerCubePosition[0], outerCubePosition[1], outerCubePosition[2])

        let innerCubePosition = [0.0, (delta - outerSize) / 2, 0.0]
        let cgInnerCubeSize = CGFloat(outerSize - delta)
        
        let innerGeometry = SCNBox(width: cgInnerCubeSize,
                                   height: cgInnerCubeSize,
                                   length: cgInnerCubeSize,
                                   chamferRadius: 0)

        innerGeometry.firstMaterial?.isDoubleSided = true
        innerGeometry.firstMaterial?.diffuse.contents = UIColor.green
        innerGeometry.firstMaterial?.lightingModel = .physicallyBased
        
        innerCube = SCNNode(geometry: innerGeometry)
        innerCube.position = SCNVector3(innerCubePosition[0], innerCubePosition[1], innerCubePosition[2])
        innerCube.scale.y = 0.0
        
        // Add animation
        let animation = CAKeyframeAnimation(keyPath: "eulerAngles")
        animation.values = [NSValue(scnVector3: SCNVector3(0, 0, 0)),
                            NSValue(scnVector3: SCNVector3(0, 2 * Float.pi, 0))]
        animation.duration = 10
        animation.repeatCount = HUGE
        innerCube.addAnimation(animation, forKey: "eulerAngles")
        outerCube.addAnimation(animation, forKey: "eulerAngles")
    }
    
    var isPaused: Bool = false {
        didSet {
            innerCube.animationPlayer(forKey: "eulerAngles")?.paused = isPaused
            outerCube.animationPlayer(forKey: "eulerAngles")?.paused = isPaused
        }
    }
    
    func updateProgressCube(scale: Float) {
        self.innerCube.scale.y = scale
        self.innerCube.position.y = (delta - size + scale * (size - delta)) / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController {

    func setupSceneKit(shadows: Bool = true) -> SCNScene {
        sceneKitView.allowsCameraControl = false

        let scene = SCNScene()
        sceneKitView.scene = scene
        scene.background.contents = backgroundGray

        let lookAtNode = SCNNode()

        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        cameraNode.camera = camera
        camera.fieldOfView = 25
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.5
        cameraNode.position = SCNVector3(x: 2.5, y: 2.0, z: 5.0)
        let lookAt = SCNLookAtConstraint(target: lookAtNode)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [ lookAt ]

        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: -1.5, y: 2.5, z: 1.5)

        if shadows {
            light.type = .directional
            light.castsShadow = true
            light.shadowSampleCount = 8
            lightNode.constraints = [ lookAt ]
        }

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = #colorLiteral(red: 0.5723067522, green: 0.5723067522, blue: 0.5723067522, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient

        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ambientNode)

        return scene
    }

    func addProgressCube(outerSize: Float, delta: Float, inScene scene: SCNScene) -> ProgressCube {
        let cube = ProgressCube(outerSize: outerSize, delta: delta)
        
        scene.rootNode.addChildNode(cube.innerCube)
        scene.rootNode.addChildNode(cube.outerCube)

        return cube
    }
    
    // Flash the cube white for a moment
    func flashCube(cube: SCNNode) {
        let start = UIColor.gray.cgColor.components!
        var end = UIColor.white.cgColor.components!
        end[0] = 0.8
        
        let duration = 0.1
        
        let changeColor = SCNAction.customAction(duration: TimeInterval(duration)) { (node, elapsedTime) -> Void in
            let percentage = abs((CGFloat(duration) / 2) - elapsedTime) / (CGFloat(duration) / 2)
            
            let color = UIColor(cgColor: CGColor(gray: start[0] * percentage + end[0] * (1 - percentage),
                                                 alpha: start[1] * percentage + end[1] * (1 - percentage)))
            cube.geometry!.firstMaterial!.diffuse.contents = color
        }

        cube.runAction(changeColor)
    }
    
}
