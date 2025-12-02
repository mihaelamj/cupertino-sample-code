/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Views and utilities for using the camera assistance feature of Nearby Interaction.
*/

import SwiftUI
import NearbyInteraction
import ARKit
import RealityKit
import os
import Combine

// The main view for the Camera Assistance feature.
struct NICameraAssistanceView: View {
    let findingMode: FindingMode
    @StateObject var sessionManager: NISessionManager

    init(mode: FindingMode) {
        findingMode = mode
        _sessionManager = StateObject(wrappedValue: NISessionManager(mode: mode))
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                VStack {
                    Spacer()
                    ZStack {
                        NIARView(findingMode: findingMode, sessionManager: sessionManager)
                            .onDisappear {
                                sessionManager.invalidate()
                            }
                            .frame(width: reader.size.width, height: reader.size.height * 0.95,
                                   alignment: .center)
                        VStack {
                            Spacer()
                            NICoachingOverlay(
                                findingMode: findingMode,
                                isConverged: sessionManager.isConverged,
                                measurementQuality: sessionManager.quality,
                                lastNearbyObject: sessionManager.latestNearbyObject,
                                showCoachingOverlay: sessionManager.showCoachingOverlay,
                                showUpdownText: sessionManager.showUpDownText)
                            .frame(width: reader.size.width,
                                   height: sessionManager.showCoachingOverlay ? reader.size.height * 0.95 : reader.size.height * 0.3,
                                   alignment: sessionManager.showCoachingOverlay ? .center : .bottom)
                            .animation(.smooth, value: sessionManager.showCoachingOverlay)
                        }.background(.clear)
                    }
                    Spacer()
                }
            }
        }
    }
}

// Previews the view.
struct NICameraAssistanceView_Previews: PreviewProvider {
    static var previews: some View {
        NICameraAssistanceView(mode: .exhibit)
        NICameraAssistanceView(mode: .visitor)
    }
}

// A subview with the AR view.
@MainActor
struct NIARView: UIViewRepresentable {

    let findingMode: FindingMode
    var sessionManager: NISessionManager
    
    init(findingMode: FindingMode, sessionManager: NISessionManager) {
        self.findingMode = findingMode
        self.sessionManager = sessionManager
    }

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        self.sessionManager.setARSession(arView.session)
        // Create a world-tracking configuration to the
        // AR session requirements for Nearby Interaction.
        // For more information,
        // see the `setARSession` function of `NISession`.
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = false
        configuration.userFaceTrackingEnabled = false
        configuration.initialWorldMap = nil
        configuration.environmentTexturing = .automatic

        // Run the view's AR session.
        arView.session.run(configuration)

        // Add the blurred view by default at the start when creating the view.
        blurView.frame = arView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(blurView)

        // Return the AR view.
        return arView
    }

    // A coordinator for updating AR content.
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // A coordinator class.
    @MainActor
    class Coordinator: NSObject {
        // A parent Nearby Interaction AR view.
        var parent: NIARView
        var peerName: String = ""
        var meshText: MeshResource?
        var meshSphere: MeshResource?
        var meshSphereArray = [MeshResource]()
        var initialSize: Float = 0
        
        // An anchor entity for placing AR content in the AR world.
        init( _ parent: NIARView) {
            self.parent = parent
            self.animationUpdates = []
        }

        // The constants.
        let sphereSeparation = Float(0.6)

        // The animation objects.
        var animationUpdates: [Cancellable?]
        var lastWorldTransform: simd_float4x4?
        var subscriptions: [AnyCancellable] = []
        // Animates an anchor entity.
        func animate(entity: HasTransform,
                     reference: Entity?,
                     height: Float,
                     scale: Float,
                     duration: TimeInterval,
                     arView: ARView,
                     index: Int) {

            // Update the location by adding the height and scaling by a factor.
            var transform = entity.transform
            transform.scale *= scale
            transform.translation.y += height

            // Move the entity over a duration.
            entity.move(to: transform.matrix,
                        relativeTo: reference,
                        duration: duration,
                        timingFunction: .default)

            // Add the animation completion monitor, if necessary.
            guard animationUpdates.count < (index + 1)
            else { return }

            // Add a monitor for the completed animation to execute it again.
            animationUpdates.append(arView.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self,
                                                     on: entity, { _ in
                // Restore the original location and scale.
                entity.position = [0, Float(index) * self.sphereSeparation, 0]
                entity.scale = entity.scale(relativeTo: entity.parent) / scale

                // Animate again to repeat.
                self.animate(entity: entity,
                             reference: reference,
                             height: height,
                             scale: scale,
                             duration: duration,
                             arView: arView,
                             index: index)
            }))
        }
        
        // Create or update the anchor entity in `exhibit` finding mode.
        // Use the coordinator to update the AR view as needed based on the
        // updated nearby object and convergence context.
        func placeSpheresInView(_ arView: ARView, _ worldTransform: simd_float4x4) {
            if let peerAnchor = arView.scene.anchors.first {
                // Update the world transform.
                peerAnchor.transform.matrix = worldTransform
            } else {
                // Create the peer anchor only once.
                let peerAnchor = AnchorEntity(.world(transform: worldTransform))
                if meshSphereArray.isEmpty {
                    for index in 0...3 {
                        // Increase the size of each sphere.
                        meshSphereArray.append(MeshResource.generateSphere(radius: 0.15 + Float(index) * 0.1))
                    }
                }

                // Add multiple spheres entity into `peerAnchor`.
                for index in 0...3 {
                    let sphere = ModelEntity(mesh: meshSphereArray[index],
                                             materials: [SimpleMaterial(color: .systemPink,
                                                                         isMetallic: true)])

                    // Add the model entity to the anchor entity.
                    peerAnchor.addChild(sphere, preservingWorldTransform: false)

                    // Update the position for each sphere by moving up the y-axis.
                    sphere.position = [0, Float(index) * sphereSeparation, 0]

                    // Add the anchor entity to the AR world.
                    arView.scene.addAnchor(peerAnchor)

                    // The animation of spheres.
                    self.animate(entity: sphere,
                                 reference: peerAnchor,
                                 height: Float(index + 1) * sphereSeparation,
                                 scale: 2.0,
                                 duration: 2.0,
                                 arView: arView,
                                 index: index)
                    }
            }
        }
                
        // Create or update the anchor entity in `visitor` finding mode.
        // Use the coordinator to update the AR view as needed based on the
        // updated nearby object and convergence context.
        func placeTextInView(_ arView: ARView, _ worldTransform: simd_float4x4, name: String, distance: Float) {
            if let peerAnchor = arView.scene.anchors.first {
                // Update the position of anchor with updated `worldTransform`.
                peerAnchor.position = [worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z]
            } else {
                // Create mesh text once for each peer.
                if meshText == nil || (peerName != name) {
                    // Add a banner that displays the provided name of the peer.
                    initialSize = 0.3 + 0.01 * distance
                    meshText = MeshResource.generateText(name,
                                                         extrusionDepth: 0.03,
                                                         font: .systemFont(ofSize: CGFloat(initialSize)),
                                                         alignment: .center,
                                                         lineBreakMode: .byWordWrapping)
                    peerName = name
                }
                // Create mesh sphere once.
                if meshSphere == nil {
                    meshSphere = MeshResource.generateSphere(radius: 0.3)
                }

                // Add a text banner and sphere entity into ARView to better
                // guide the person to locate the peer device.
                let peerAnchor = AnchorEntity(.world(transform: matrix_identity_float4x4))
                if let text = meshText, let sphere = meshSphere {
                    // Create text entity.
                    let textEntity = ModelEntity(mesh: text, materials: [SimpleMaterial(color: .systemPink, isMetallic: false)])
                    peerAnchor.addChild(textEntity)

                    // Create sphere entity.
                    let sphereEntity = ModelEntity(mesh: sphere,
                                                   materials: [SimpleMaterial(color: .systemPink,
                                                                              isMetallic: true)])
                    peerAnchor.addChild(sphereEntity)
                    
                    let center = (text.bounds.max - text.bounds.min)
                    // Place `textEntity` in the center of `peerAnchor`.
                    textEntity.position = -1 / 2 * [center.x, center.y, center.z]
                    // Place `sphereEntity` above `textEntity(y-xis) 0.2`.
                    sphereEntity.position = textEntity.position + [0, initialSize + 0.2, 0]

                    // Make `textEntity` always faces the same direction as the device camera.
                    arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
                        textEntity.look(at: arView.cameraTransform.translation, from: textEntity.position(relativeTo: nil), relativeTo: nil)
                        textEntity.transform.rotation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
                    }.store(in: &subscriptions)
                    
                    // Add the anchor entity to the AR world.
                    arView.scene.addAnchor(peerAnchor)

                    // Update the position of `peerAnchor` from current `worldTransform`.
                    peerAnchor.position = [worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z]
                }
            }
        }

        // Update the peer anchor.
        func updatePeerAnchor(arView: ARView, currentWorldTransform: simd_float4x4?, name: String, distance: Float) {
            // Check whether its same world transform than previous one.
            if currentWorldTransform == lastWorldTransform { return }
            
            // Check whether the framework fully resolves the world transform.
            if let worldTransform = currentWorldTransform {
                // Don't blur an ARView when the status is fully converged and
                // there is a new `worldTransform`.
                parent.blurView.isHidden = true

                // Update the ARView scene with current `worldTransform` value.
                switch parent.findingMode {
                    // Place spheres into the view for `exhibit` finding mode.
                case .exhibit: placeSpheresInView(arView, worldTransform)
                    // Place text into the view for `visitor` finding mode.
                case .visitor: placeTextInView(arView, worldTransform, name: name, distance: distance)
                }
                
                // Cached current `worldTransform`.
                lastWorldTransform = worldTransform
            } else {
                // Blur the ARView when the status isn't fully converged and
                // with no valid `worldTransform`.
                parent.blurView.isHidden = false
                
                // Remove all `peerAnchor` and `childEntity`objects  from the ARView scene.
                for peerAnchor in arView.scene.anchors {
                    for childEntity in peerAnchor.children {
                        childEntity.removeFromParent()
                    }
                    peerAnchor.removeFromParent()
                }
                arView.scene.anchors.removeAll()

                // Cancel all left text facing subscriptions under visitor mode.
                subscriptions.forEach { $0.cancel() }
                subscriptions.removeAll()

                // Cancel all pending sphere animations under exhibit mode.
                animationUpdates.forEach { $0?.cancel() }
                animationUpdates.removeAll()
                
                // Clear the cached `worldTransform`.
                lastWorldTransform = nil
            }
        }
    }

    // Update the AR view.
    func updateUIView(_ uiView: ARView, context: Context) {
        guard let distance = sessionManager.latestNearbyObject?.distance else { return }
        context.coordinator.updatePeerAnchor(arView: uiView, currentWorldTransform: sessionManager.currentWorldTransform,
                                             name: sessionManager.connectedPeerName, distance: distance)
    }
}
