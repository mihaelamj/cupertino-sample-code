/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show the reconstruction progress.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "BottomBarView")

struct BottomBarView: View {
    @Binding var firstModelFileURL: URL?
    @Binding var processedRequestsDetailLevel: [String]

    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @State private var processingComplete = false

    var body: some View {
        VStack {
            if processingComplete {
                ReprocessView()
            } else {
                HStack {
                    if let imageFolder = appDataModel.imageFolder, let firstImageURL = getFirstImage(from: imageFolder) {
                        ThumbnailView(imageFolderURL: firstImageURL, frameSize: CGSize(width: 55, height: 55))
                    }
                    ReconstructionProgressView(firstModelFileURL: $firstModelFileURL,
                                               processedRequestsDetailLevel: $processedRequestsDetailLevel,
                                               processingComplete: $processingComplete)
                }
                .padding()
            }
        }
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { !$0.hasDirectoryPath && isLoadableImageFile($0) }
            .sorted(by: { $0.path < $1.path })
            .first
        return imagesURL
    }

    private func isLoadableImageFile(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let suffix = url.pathExtension.lowercased()
        return ImageHelper.validImageSuffixes.contains(suffix)
    }

}
