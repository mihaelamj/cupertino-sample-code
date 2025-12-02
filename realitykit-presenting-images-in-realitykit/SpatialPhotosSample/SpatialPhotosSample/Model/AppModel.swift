/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main model containing observable data that can used across the views.
*/

import RealityKit
import SwiftUI

enum Spatial3DImageState {
    case notGenerated
    case generating
    case generated
}

@MainActor
@Observable
class AppModel {
    let imageNames: [String] = [
        "architecture-windmill-tulips",
        "food-lemon-tree",
        "animals-cat-sleeping-in-ruins",
        "animals-bee-on-purple-flower",
        "architecture-hampi-india"
    ]
    var imageURLs: [URL] {
        var imageURLs: [URL] = []
        for imageName in imageNames {
            guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: ".jpeg") else {
                print("Unable to find image \(imageName) in bundle.")
                continue
            }
            imageURLs.append(imageURL)
        }
        return imageURLs
    }
    var imageIndex: Int = 0
    var imageURL: URL? = nil
    var imageAspectRatio: CGFloat = 1.0
    var contentEntity: Entity = Entity()
    var spatial3DImageState: Spatial3DImageState = .notGenerated
    var spatial3DImage: ImagePresentationComponent.Spatial3DImage? = nil

    init() {
        imageURL = imageURLs[imageIndex]
    }

    func createImagePresentationComponent() async {
        guard let imageURL else {
            print("ImageURL is nil.")
            return
        }
        spatial3DImageState = .notGenerated
        spatial3DImage = nil
        do {
            spatial3DImage = try await ImagePresentationComponent.Spatial3DImage(contentsOf: imageURL)
        } catch {
            print("Unable to initialize spatial 3D image: \(error.localizedDescription)")
        }

        guard let spatial3DImage else {
            print("Spatial3DImage is nil.")
            return
        }
        
        let imagePresentationComponent = ImagePresentationComponent(spatial3DImage: spatial3DImage)
        contentEntity.components.set(imagePresentationComponent)
        if let aspectRatio = imagePresentationComponent.aspectRatio(for: .mono) {
            imageAspectRatio = CGFloat(aspectRatio)
        }
    }

    func generateSpatial3DImage() async throws {
        guard spatial3DImageState == .notGenerated else {
            print("Spatial 3D image already generated or generation is in progress.")
            return
        }
        guard let spatial3DImage else {
            print("createImagePresentationComponent.")
            return
        }
        guard var imagePresentationComponent = contentEntity.components[ImagePresentationComponent.self] else {
            print("ImagePresentationComponent is missing from the entity.")
            return
        }
        // Set the desired viewing mode before generating so that it will trigger the
        // generation animation.
        imagePresentationComponent.desiredViewingMode = .spatial3D
        contentEntity.components.set(imagePresentationComponent)
        
        // Generate the Spatial3DImage scene.
        spatial3DImageState = .generating
        try await spatial3DImage.generate()
        spatial3DImageState = .generated

        if let aspectRatio = imagePresentationComponent.aspectRatio(for: .spatial3D) {
            imageAspectRatio = CGFloat(aspectRatio)
        }
    }
}
