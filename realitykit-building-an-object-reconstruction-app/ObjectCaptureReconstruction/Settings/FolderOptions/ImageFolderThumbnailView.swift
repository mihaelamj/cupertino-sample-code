/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Pick five thumbnails from the image URLs and show them.
*/

import SwiftUI

struct ImageFolderThumbnailView: View {
    @Binding var imageURLs: [URL]

    @State private var thumbnailURLs: [URL]?
    static private let numThumbnailsToDisplay = 5

    var body: some View {
        HStack {
            if let thumbnailURLs {
                ForEach(thumbnailURLs, id: \.self) { thumbnailURL in
                    ThumbnailView(imageFolderURL: thumbnailURL, frameSize: CGSize(width: 45, height: 45))
                }
            } else {
                Image(systemName: "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(height: 35)
        .onChange(of: imageURLs) {
            guard !imageURLs.isEmpty else {
                thumbnailURLs = nil
                return
            }

            // Pick 5 images to display.
            let numImages = imageURLs.count
            if numImages < Self.numThumbnailsToDisplay {
                thumbnailURLs = imageURLs
            } else {
                let step = numImages / Self.numThumbnailsToDisplay
                let filteredIndices = imageURLs.indices.filter { $0 % step == 0 }[0..<Self.numThumbnailsToDisplay]
                thumbnailURLs = filteredIndices.map { imageURLs[$0] }
            }
        }
    }
}
