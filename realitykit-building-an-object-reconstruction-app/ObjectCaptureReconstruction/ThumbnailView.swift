/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show an image thumbnail.
*/

import SwiftUI

struct ThumbnailView: View {
    let imageFolderURL: URL
    let frameSize: CGSize
    @State private var image: CGImage?

    var body: some View {
        VStack {
            if let image {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .clipped()
        .cornerRadius(6)
        .task {
            image = await createThumbnail(url: imageFolderURL)
        }
    }

    private nonisolated func createThumbnail(url: URL) async -> CGImage? {
        let maxPixelSize = max(frameSize.width, frameSize.height) * 2
        let options = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            return nil
        }
        return thumbnail
    }
}
