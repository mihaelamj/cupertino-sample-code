/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view containing the entity with the ImagePresentationComponent.
*/

import RealityKit
import SwiftUI

struct ImagePresentationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(SceneDelegate.self) private var sceneDelegate

    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                await appModel.createImagePresentationComponent()
                // Scale the entity to fit in the bounds.
                let availableBounds = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                scaleImagePresentationToFit(in: availableBounds)
                content.add(appModel.contentEntity)
            } update: { content in
                guard let presentationScreenSize = appModel
                    .contentEntity
                    .observable
                    .components[ImagePresentationComponent.self]?
                    .presentationScreenSize, presentationScreenSize != .zero else {
                        print("Unable to get a valid presentation screen size from the content entity.")
                        return
                }
                // Position the entity at the back of the window.
                let originalPosition = appModel.contentEntity.position(relativeTo: nil)
                appModel.contentEntity.setPosition(SIMD3<Float>(originalPosition.x, originalPosition.y, 0.0), relativeTo: nil)
                // Scale the entity to fit in the bounds.
                let availableBounds = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                scaleImagePresentationToFit(in: availableBounds)
            }
            .onAppear() {
                guard let windowScene = sceneDelegate.windowScene else {
                    print("Unable to get the window scene. Unable to set the resizing restrictions.")
                    return
                }
                // Ensure that the scene resizes uniformly on X and Y axes.
                windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: .uniform))
            }
            .onChange(of: appModel.imageAspectRatio) { _, newAspectRatio in
                guard let windowScene = sceneDelegate.windowScene else {
                    print("Unable to get the window scene. Resizing is not possible.")
                    return
                }

                let windowSceneSize = windowScene.effectiveGeometry.coordinateSpace.bounds.size

                //  width / height = aspect ratio
                // Change ONLY the width to match the aspect ratio.
                let width = newAspectRatio * windowSceneSize.height

                // Keep the height the same.
                let size = CGSize(width: width, height: UIProposedSceneSizeNoPreference)

                UIView.performWithoutAnimation {
                    // Update the scene size.
                    windowScene.requestGeometryUpdate(.Vision(size: size))
                }
            }
            .onChange(of: appModel.imageURL) {
                Task {
                    await appModel.createImagePresentationComponent()
                }
            }
        }
        .aspectRatio(appModel.imageAspectRatio, contentMode: .fit)
    }
    
    /// Fit the image presentation inside a bounding box by scaling the content entity.
    func scaleImagePresentationToFit(in boundsInMeters: BoundingBox) {
        guard let imagePresentationComponent = appModel.contentEntity.components[ImagePresentationComponent.self] else {
            return
        }

        let presentationScreenSize = imagePresentationComponent.presentationScreenSize
        let scale = min(
            boundsInMeters.extents.x / presentationScreenSize.x,
            boundsInMeters.extents.y / presentationScreenSize.y
        )

        appModel.contentEntity.scale = SIMD3<Float>(scale, scale, 1.0)
    }
}
