/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of types that define the app's export behavior.
*/

import AVFoundation

/// An enumeration that identifies the type of exporter implementation.
enum ExporterType: CaseIterable {
    /// Export using `AVAssetExportSession`.
    case exportSession
    /// Export using `AVAssetReader` and `AVAssetWriter`.
    case readerWriter
    
    /// A human-readable description of the exporter type.
    var description: String {
        switch self {
        case .exportSession:
            return "Export Session"
        case .readerWriter:
            return "Reader & Writer"
        }
    }
    
    /// Creates an instance of the corresponding exporter.
    func createExporter() -> Exporter {
        switch self {
        case .exportSession:
            return ExportSessionExporter()
        case .readerWriter:
            return ReaderWriterExporter()
        }
    }
}

/// A protocol that defines the interface for exporting media.
protocol Exporter {
    /// The current status of the export operation.
    var status: ExporterStatus { get }
    /// Exports the source media with the indicated compositor.
    /// - Parameters:
    ///   - sourceURL: The source video file to export.
    ///   - customCompositorClass: The custom compositor class to use during export.
    ///   - compositorOutputsStereo: A Boolean value that indicates whether the compositor outputs stereo video.
    func export(asset: AVAsset, videoComposition: AVVideoComposition?) async throws
}

/// An enumeration that defines the status of an exporter object.
enum ExporterStatus {
    /// Indicates the exporter is currently idle.
    case idle
    /// Indicates the exporter is currently exporting media.
    /// - Parameter progress: The current progress of the export operation.
    case exporting(progress: Double)
    /// Indicates the export operation is complete.
    /// - Parameter outputURL: The output URL of the exported media.
    case complete(outputURL: URL)
    /// Indicates the export operation failed.
    /// - Parameter error: An error that describes the failure.
    case failed(Error)
}

/// An enumeration that defines possible errors that occur when exporting media.
enum ExportError: String, Error {
    /// The specified asset contains no video tracks.
    case noVideoTracks = "no video tracks"
    /// The exporter wasn't able to create an asset reader.
    case noAssetReader = "failed to create asset reader"
    /// The exporter wasn't able to create an asset writer.
    case noAssetWriter = "failed to create asset writer"
    /// The exporter wasn't able to create an export session.
    case noExportSession = "failed to create export session"
    /// The export was cancelled.
    case cancelled = "export canceled"
    /// The export operation failed.
    case failed = "export failed"
    /// Failed to append tagged buffers to writer input.
    case appendTaggedBuffersFailed = "failed to append tagged buffers to writer input"
}
