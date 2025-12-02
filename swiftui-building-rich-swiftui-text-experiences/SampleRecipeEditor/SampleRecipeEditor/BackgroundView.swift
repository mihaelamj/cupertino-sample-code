/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The background for the detail view.
*/

import SwiftUI
import UniformTypeIdentifiers

/// The background for the detail view.
///
/// Provide the image data from the recipe model. If no data is provided the
/// view falls back to a default image from the asset catalog instead.
struct BackgroundView: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let imageData {
                ImageWithPlaceholder(imageData) {
                    Color.clear
                }
            } else {
                Image("objects-cauldron-on-fire")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(height: 200)
        .mask(LinearGradient(
            gradient: Gradient(colors: [.black, .clear]),
            startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
}

/// A view that asynchronously loads an image from data and shows a placeholder
/// until the image loads successfully.
struct ImageWithPlaceholder<Placeholder: View>: View {
    let imageData: Data?
    let placeholder: () -> Placeholder

    @State private var loadedImage: Image?

    init(_ imageData: Data?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.imageData = imageData
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: imageData) {
            guard let imageData else {
                loadedImage = nil
                return
            }

            self.loadedImage = try? await Image(importing: imageData, contentType: .image)
        }
    }

    private var image: Image? {
        if imageData != nil {
            loadedImage
        } else {
            nil
        }
    }
}
