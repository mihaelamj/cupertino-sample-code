/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a thumbnail for a video URL.
*/

import AVKit
import SwiftUI

struct ThumbnailView: View {
    let url: URL
    @State var imageResult: Result<CGImage, Error>?

    @ViewBuilder
    var filmThumbnail: some View {
        // During image generation, or if it fails,
        // display the film SF Symbols on a black background.
        Color.black

        Image(systemName: "film")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.secondary)
            .font(.largeTitle)
            .padding(20.0)
    }

    var body: some View {
        ZStack {
            switch imageResult {
            case .success(let image):
                Image(uiImage: UIImage(cgImage: image))
                    // Allow the image to resize to fit the container.
                    .resizable()
                    // Fit the image so it reflects the orientation
                    // and size of the video.
                    .aspectRatio(contentMode: .fit)
            case .failure:
                filmThumbnail
            case .none:
                filmThumbnail
                ProgressView()
            }
        }
        .task {
            // Prevent generating an image if you already have one.
            guard imageResult == nil else { return }

            await generateThumbnail()
        }
    }
}

extension ThumbnailView {
    @concurrent
    func generateThumbnail() async {
        let asset: AVAsset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: 300, height: 300 * (16 / 9))

        guard let duration = try? await asset.load(.duration) else { return }
        let seconds = duration.seconds / 2
        let halfway: CMTime = .init(seconds: seconds, preferredTimescale: 1)
        do {
            let image = try await generator.image(at: halfway).image
            await MainActor.run {
                imageResult = .success(image)
            }
        } catch {
            await MainActor.run {
                imageResult = .failure(error)
            }
        }
    }
}

#Preview {
    ThumbnailView(
        url: .init(string: "https://playgrounds-cdn.apple.com/assets/beach/index.m3u8")!,
        imageResult: nil
    )
}
