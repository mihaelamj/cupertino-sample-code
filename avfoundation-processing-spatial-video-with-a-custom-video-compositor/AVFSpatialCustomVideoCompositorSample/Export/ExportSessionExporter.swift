/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that uses an export session to export the composited video.
*/

import Observation
import AVFoundation
import os

@Observable
class ExportSessionExporter: Exporter {

    private(set) var status: ExporterStatus = .idle
    private var outputURL: URL!

    func export(asset: AVAsset, videoComposition: AVVideoComposition? = nil) async throws {

        // If this method receives a video composition that produces stereo output, use an MV-HEVC preset.
        // Note: the `outputsStereo` property is an app-specific extension.
        let preset = if let videoComposition, videoComposition.outputsStereo {
            AVAssetExportPresetMVHEVC4320x4320
        }
        // Otherwise, use a standard HEVC preset.
        else {
            AVAssetExportPresetHEVCHighestQuality
        }

        // Attempt to create an export session with the selected preset.
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ExportError.noExportSession
        }

        // If a valid video composition was passed to this method, set it on the export session.
        if let videoComposition {
            exportSession.videoComposition = videoComposition
        }

        /// Use extension `movieOutputURL` property.
        outputURL = FileManager.default.movieOutputURL

        await withThrowingTaskGroup(of: Void.self) { group in
            // Export task.
            group.addTask {
                do {
                    // Export the asset to the specified output URL.
                    try await exportSession.export(to: self.outputURL, as: .mov)
                    self.status = .complete(outputURL: self.outputURL)
                } catch {
                    logger.log("Export session failed: \(error.localizedDescription)")
                    throw ExportError.failed
                }
            }

            // Progress update tasks.
            group.addTask { [weak self] in
                guard let self else { return }
                // Asynchronously monitor the export session's progress.
                for await state in exportSession.states(updateInterval: 0.1) {
                    self.updateStatus(exportSessionState: state)
                }
            }
        }
    }

    func updateStatus(exportSessionState: AVAssetExportSession.State) {
        switch exportSessionState {
        case .waiting:
            status = .exporting(progress: 0.0)
        case .exporting(let progress):
            if progress.isFinished {
                status = .complete(outputURL: outputURL)
            } else if progress.isCancelled {
                status = .failed(ExportError.cancelled)
            } else {
                status = .exporting(progress: progress.fractionCompleted)
            }
        default:
            status = .idle
        }
    }
}
