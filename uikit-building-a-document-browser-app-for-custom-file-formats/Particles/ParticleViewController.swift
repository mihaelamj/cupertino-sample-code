/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that hosts a SceneKit view in which the particle system is being rendered.
*/

import UIKit
import SceneKit

class ParticleViewController: UIViewController {
    
    private let sceneView = SCNView()
    
    var document: Document? {
        didSet {
            navigationItem.title = document?.presentedItemURL?.lastPathComponent
            
            loadViewIfNeeded()
            updateScene()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = document?.presentedItemURL?.lastPathComponent
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTaped))
        
        let scene = SCNScene()
        scene.background.contents = UIColor.darkGray
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 3, z: 6)
        scene.rootNode.addChildNode(cameraNode)
        
        // Scene View
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.scene?.isPaused = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sceneView.scene?.isPaused = false
    }
    
    func updateScene() {
        guard let document = document,
            let particleSystem = document.particleSystem else { return }
        
        particleSystem.warmupDuration = 2.0
        particleSystem.particleImage = #imageLiteral(resourceName: "spark.png")
        
        let particleSystemNode = SCNNode()
        particleSystemNode.addParticleSystem(particleSystem)
        sceneView.scene?.rootNode.addChildNode(particleSystemNode)
    }
    
    // MARK: UI Actions
    
    @objc
    func doneButtonTaped() {
        guard let documentViewController = navigationController?.parent as? DocumentViewController else {
            return
        }
        documentViewController.dismissDocumentViewController()
    }
    
    // MARK: Thumbnailing
    
    func snapshot() -> UIImage {
        
        // Particles file thumbnails are simply a visual snapshot of the `sceneView`.
        return sceneView.snapshot()
    }
}
