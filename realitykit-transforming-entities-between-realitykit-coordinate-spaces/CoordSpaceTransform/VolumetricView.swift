/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view containing the volumetric reality view.
*/

import RealityKit
import SwiftUI

/// The view that contains the contents of the volumetric window.
struct VolumetricView: View {
    /// The app's observable data model.
    @Environment(AppModel.self) private var appModel
    
    /// The attachment that displays the cube's translation relative to the immersive coordinate space.
    @State private var immersiveAttachmentEntity: Entity!
    
    @State private var subscriptionToMoveCompleted: EventSubscription?

    var body: some View {
        GeometryReader3D { proxy in
            RealityView { content, attachments in
                createContentAndPositionAttachments(content, attachments)
                subscriptionToMoveCompleted = content.subscribe(
                    to: AnimationEvents.PlaybackCompleted.self,
                    on: appModel.volumeCube, { _ in
                        appModel.updateTransform(relativeTo: .scene)
                        appModel.updateTransform(relativeTo: .immersiveSpace)
                    })
                // Update the transforms once the move to the center of the volumetric window
                // has been completed.
                appModel.updateTransform(relativeTo: .scene)
                appModel.updateTransform(relativeTo: .immersiveSpace)
            } update: { content, attachments in
                if let cube = content.entities.first(where: { $0.name == "volumetricWindowCube" }) {
                    cube.scale = content.convert(proxy.frame(in: .local), from: .local, to: .scene).extents
                }
            } attachments: {
                createAttachment("immersive", appModel.spaceTransform)
                createAttachment("scene", appModel.sceneTransform)
            }
            .onChange(of: appModel.immersiveSpaceState) {
                immersiveAttachmentEntity.isEnabled = appModel.immersiveSpaceState == .open
            }
            .onGeometryChange(
                for: AffineTransform3D.self, of: onGeometryChangeTransform,
                action: updateImmersiveSpaceTransform
            )
            .gesture(doubleTapMove)
            .gesture(appModel.dragUpdateTransforms)
            .toolbar {
                toolbarContent
            }
        }
    }

    /// Creates the reality view content and positions the attachments.
    ///
    /// The method does the following:
    /// - Adds a cube entity that moves between the volumetric window and the immersive space.
    /// - Adds a cube entity that fills the volume of the window to show the extent of the window.
    /// - Positions the scene and immersive space transform text attachments.
    /// - Parameters:
    ///   - content: The `RealityViewContent` of the volumetric window that the system adds the cube entities to.
    ///   - attachments: The attachments associated with the reality view positioned relative to the cube.
    private func createContentAndPositionAttachments(
        _ content: RealityViewContent, _ attachments: RealityViewAttachments
    ) {
        // Create the cube that moves between the volumetric and immersive views.
        createCube()

        // Create the cube that's the same size as the volumetric window.
        let volumetricWindowCube = createVolumetricWindowCube()
        volumetricWindowCube.name = "volumetricWindowCube"

        // Add the entities to the reality view content.
        content.add(appModel.volumeRootEntity)
        content.add(appModel.volumeCubeLastSceneTransformEntity)
        content.add(volumetricWindowCube)

        // Position the scene transform attachment below the volume cube.
        appModel.sceneAttachmentEntity = positionAttachment(
            "scene", [0, -0.15, 0], attachments)
        
        // Position the immersive space transform attachment above the volume cube.
        immersiveAttachmentEntity = positionAttachment(
            "immersive", [0, 0.15, 0], attachments)
        immersiveAttachmentEntity?.isEnabled = false
    }

    /// Create the cube that a person moves between the volumetric and immersive views.
    private func createCube() {
        appModel.volumeCube.components.set([
            ModelComponent(
                mesh: .generateBox(size: 0.1, cornerRadius: 0.01),
                materials: [appModel.volumetricMaterial]),
            InputTargetComponent(allowedInputTypes: .indirect),
            HoverEffectComponent(),
            CollisionComponent(shapes: [
                ShapeResource.generateBox(size: [0.1, 0.1, 0.1])
            ])
        ])
        
        // Make the volume cube a subentity of the volumetric window's root.
        appModel.volumeRootEntity.addChild(appModel.volumeCube)
    }
    
    /// Creates the cube entity, which is the size of the volumetric window. This helps
    ///  visualize the bounds of the volumetric window.
    /// - Returns: The cube entity that represents the size of the volumetric window.
    private func createVolumetricWindowCube() -> ModelEntity {
        var volumetricWindowCubeMaterial = SimpleMaterial(
            color: #colorLiteral(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.4),
            roughness: 0.5,
            isMetallic: false)

        volumetricWindowCubeMaterial.faceCulling = .front

        let volumetricWindowCube = ModelEntity(
            mesh: .generateBox(size: 1.0, cornerRadius: 0.1),
            materials: [volumetricWindowCubeMaterial])

        return volumetricWindowCube
    }
    
    /// Create the text attachment showing the given transform's translation values.
    /// - Parameters:
    ///   - id: The identifier for the attachment, which also appears in the text.
    ///   - transform: The transform with the translation that appears in the text.
    /// - Returns: The attachment containing the text.
    private func createAttachment(_ id: String, _ transform: Transform) -> Attachment<some View> {
        // Set the precision of the value of each axis to two decimal points.
        let xFormatted = String(format: "%.2f", transform.translation.x)
        let yFormatted = String(format: "%.2f", transform.translation.y)
        let zFormatted = String(format: "%.2f", transform.translation.z)
        
        return Attachment(id: id) {
            Text("\(id): \n x: \(xFormatted) y: \(yFormatted) z: \(zFormatted)")
                .font(.extraLargeTitle)
                .padding()
                .glassBackgroundEffect()
                .multilineTextAlignment(.center)
        }
    }
    
    /// Position the attachment relative to the volume cube.
    /// - Parameters:
    ///   - id: The identifier of the attachment containing the text.
    ///   - positionOffset: The position relative to the root of the attachment that is the volume cube.
    ///   - attachments: The reality view attachments associated with the volumetric view.
    /// - Returns: The entity associated with the attachment.
    private func positionAttachment(
        _ id: String, _ positionOffset: SIMD3<Float>,
        _ attachments: RealityViewAttachments
    ) -> Entity? {
        // Find the attachment using the identifier.
        guard let attachment = attachments.entity(for: id) else {
            return nil
        }
        
        // Make the attachment a subentity of the volume cube.
        appModel.volumeCube.addChild(attachment)
        
        // Set the attachment's position relative to the volume cube.
        attachment.position = positionOffset
        
        // Ensure that the attachment always orients toward the active camera.
        attachment.components.set(BillboardComponent())

        return attachment
    }
    
    /// Move the cube from a volumetric window to an immersive space using a double-tap gesture.
    private var doubleTapMove: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                moveCubeFromVolumetricWindowToImmersiveSpace()
            }
    }
    
    /// Moves the cube from the volumetric window to the immersive space.
    private func moveCubeFromVolumetricWindowToImmersiveSpace() {
        // Only move the cube if the immersive space is open.
        guard appModel.immersiveSpaceState == .open else { return }

        // Record the cube's transform before moving it to the immersive space.
        // The app uses this information to move the cube back to the volumetric window.
        appModel.volumeCubeLastSceneTransformEntity.transform = appModel.volumeCube.transform

        // Get the transformation matrix of the cube relative to the immersive space.
        let cubeToSpaceMatrix = appModel.volumeCube.transformMatrix(relativeTo: .immersiveSpace)

        // Add the cube as a subentity of the immersive space's root entity.
        appModel.immersiveSpaceRootEntity.addChild(appModel.volumeCube)
        
        // Set the transformation matrix of the cube relative to the immersive space.
        appModel.volumeCube.setTransformMatrix(cubeToSpaceMatrix ?? matrix_identity_float4x4,
                                               relativeTo: appModel.volumeCube.parent)

        // Change the material to the immersive space material.
        appModel.volumeCube.components[ModelComponent.self]?.materials = [
            appModel.immersiveSpaceMaterial
        ]

        // Disable the scene transform attachment because the volume cube is in the immersive space.
        appModel.sceneAttachmentEntity?.isEnabled = false
        
        appModel.cubeInImmersiveSpace = true
    }

    /// Handle the change in the transform of the volumetric window.
    /// - Parameter proxy: The proxy structure to access the transform when it changes.
    /// - Returns: The transform after conversion to immersive space.
    /// Note: The `updateImmersiveSpaceTransform` action doesn't use the return value.
    private func onGeometryChangeTransform(_ proxy: GeometryProxy) -> AffineTransform3D {
        return proxy.transform(in: .immersiveSpace) ?? .identity
    }
    
    /// Update the immersive space transform in the app model.
    /// - Parameter transform: The transform value of the volumetric window that changed.
    /// Note: This method doesn't use the transform parameter.
    private func updateImmersiveSpaceTransform(_ transform: AffineTransform3D) {
        appModel.updateTransform(relativeTo: .immersiveSpace)
    }
    
    /// The toolbar item group that contains the immersive space toggle button.
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            toolBarContentView
        }
    }

    /// The view for the toolbar that contains the immersive space toggle button.
    @ViewBuilder
    private var toolBarContentView: some View {
        VStack {
            ToggleImmersiveSpaceButton()

            Group {
                if appModel.cubeInImmersiveSpace {
                    Button {
                        appModel.moveCubeFromImmersiveSpaceToVolumetricWindow()
                    } label: {
                        Text("Move Cube to Volumetric Window")
                    }
                } else {
                    Button {
                        moveCubeFromVolumetricWindowToImmersiveSpace()
                    } label: {
                        Text("Move Cube to Immersive Space")
                    }
                }
            }.disabled(appModel.immersiveSpaceState != .open)
            
            Button {
                if appModel.cubeInImmersiveSpace {
                    // Set the cube's last transform position to the center of the window.
                    appModel.volumeCubeLastSceneTransformEntity.position = SIMD3<Float>(0, 0, 0)

                    if appModel.immersiveSpaceState == .open {
                        appModel.moveCubeFromImmersiveSpaceToVolumetricWindow()
                    } else if appModel.immersiveSpaceState == .closed {
                        appModel.makeCubeSubEntityOfVolumeRoot()
                    }
                } else {
                    appModel.volumeCube.move(
                        to: .identity,
                        relativeTo: appModel.volumeCube.parent,
                        duration: 0.5,
                        timingFunction: .easeOut)
                }
            } label: {
                Text("Reset Cube")
            }.disabled(appModel.immersiveSpaceState == .inTransition)
        }
    }
}

#Preview(windowStyle: .volumetric) {
    VolumetricView()
        .environment(AppModel())
}
