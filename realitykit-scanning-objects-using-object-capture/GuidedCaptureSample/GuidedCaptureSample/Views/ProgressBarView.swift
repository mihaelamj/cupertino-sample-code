/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Encapsulated View support for the scanning progress meter.
*/

// Should not depend on the data model, but driven from functional state passed into it.

import RealityKit
import SwiftUI

struct ProgressBarView: View {
    @Environment(AppDataModel.self) var appModel
    // The progress value from 0 to 1 that describes the amount of coverage completed.
    var progress: Float
    var estimatedRemainingTime: TimeInterval?
    var processingStageDescription: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var formattedEstimatedRemainingTime: String? {
        guard let estimatedRemainingTime else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: estimatedRemainingTime)
    }

    private var numOfImages: Int {
        guard let folderManager = appModel.captureFolderManager else { return 0 }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: folderManager.imagesFolder,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }
        return urls.filter { $0.pathExtension.uppercased() == "HEIC" }.count
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text(processingStageDescription ?? LocalizedString.processing)

                    Spacer()

                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .bold()
                        .monospacedDigit()
                }
                .font(.body)

                ProgressView(value: progress)
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .center) {
                    Image(systemName: "photo")

                    Text(String(numOfImages))
                        .frame(alignment: .bottom)
                        .hidden()
                        .overlay {
                            Text(String(numOfImages))
                                .font(.caption)
                                .bold()
                        }
                }
                .font(.subheadline)
                .padding(.trailing, 16)

                VStack(alignment: .leading) {
                    Text(LocalizedString.processingModelDescription)

                    Text(String.localizedStringWithFormat(LocalizedString.estimatedRemainingTime,
                                                          formattedEstimatedRemainingTime ?? LocalizedString.calculating))
                }
                .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
    }

    private struct LocalizedString {
        static let processing = NSLocalizedString(
            "Processing (Object Capture)",
            bundle: Bundle.main,
            value: "Processing…",
            comment: "Processing title for object reconstruction."
        )

        static let processingModelDescription = NSLocalizedString(
            "Keep app running while processing. (Object Capture)",
            bundle: Bundle.main,
            value: "Keep app running while processing.",
            comment: "Description displayed while processing the models."
        )

        static let estimatedRemainingTime = NSLocalizedString(
            "Estimated time remaining: %@ (Object Capture)",
            bundle: Bundle.main,
            value: "Estimated time remaining: %@",
            comment: "Estimated processing time it takes to reconstruct the object."
        )

        static let calculating = NSLocalizedString(
            "Calculating… (Estimated time, Object Capture)",
            bundle: Bundle.main,
            value: "Calculating…",
            comment: "When estimated processing time isn't available yet."
        )
    }

}
