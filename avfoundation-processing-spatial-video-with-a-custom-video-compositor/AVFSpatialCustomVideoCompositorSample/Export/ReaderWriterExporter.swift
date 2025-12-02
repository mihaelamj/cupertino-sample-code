/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that uses an asset reader and writer to export the composited video.
*/

import os
@preconcurrency import AVFoundation
import VideoToolbox

@Observable
class ReaderWriterExporter: Exporter {

    private(set) var status: ExporterStatus = .idle

    private var assetReader: AVAssetReader?
    private var readerOutput: AVAssetReaderOutput?
    private var assetWriter: AVAssetWriter?
    
    /// Provides an interface for sending tagged buffers to writer input.
    private var taggedBufferGroupReceiver: AVAssetWriterInput.TaggedPixelBufferGroupReceiver?
    private var writerInput: AVAssetWriterInput?

    func export(asset: AVAsset, videoComposition: AVVideoComposition?) async throws {

        status = .idle

        // Determine the asset duration so the app can calculate the export percentage complete.
        let assetDuration = try await asset.load(.duration).seconds

        assetReader = try? AVAssetReader(asset: asset)
        guard let assetReader else {
            throw ExportError.noAssetReader
        }

        guard let videoTracks = try? await asset.loadTracks(withMediaType: .video),
              let firstVideoTrack = videoTracks.first else {
            throw ExportError.noVideoTracks
        }
        readerOutput = try await buildAssetReaderOutput(videoTracks: videoTracks, videoComposition: videoComposition)

        if let readerOutput {
            assetReader.add(readerOutput)
        }

        let outputURL = FileManager.default.movieOutputURL

        assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mov)
        guard let assetWriter else {
            throw ExportError.noAssetWriter
        }

        // Build video settings for the writer input.
        let videoSettings = try await buildOutputSettingsForAssetWriterInput(
            sourceVideoTrack: firstVideoTrack,
            compositorOutputsStereo: videoComposition?.outputsStereo ?? false
        )

        writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

        if let writerInput {
            if let videoComposition, videoComposition.outputsStereo {
                // Stereo output video composition needs a `TaggedPixelBufferGroupReceiver` object for sending tagged buffers to the writer input.
                let pixelBufferAttributes = CVPixelBufferCreationAttributes(
                    CVPixelBufferAttributes(pixelFormatTypes: [CVPixelFormatType(rawValue: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange)])
                )
                taggedBufferGroupReceiver = assetWriter.inputTaggedPixelBufferGroupReceiver(for: writerInput, pixelBufferAttributes: pixelBufferAttributes)
            } else {
                assetWriter.add(writerInput)
            }
        }

        await performAssetReadingAndWriting(assetDuration: assetDuration, tempURL: outputURL)
    }
    
    /// Creates an object that reads from the first video track of the given asset, applying the video composition if there is one.
    ///
    /// - Parameters:
    ///   - videoTracks: The video tracks of the asset.
    ///   - videoComposition: The video composition to use when reading from the asset.
    private func buildAssetReaderOutput(videoTracks: [AVAssetTrack], videoComposition: AVVideoComposition?) async throws -> AVAssetReaderOutput {

        guard let firstVideoTrack = videoTracks.first else {
            throw ExportError.noVideoTracks
        }

        let readerOutput: AVAssetReaderOutput

        let outputSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange)
        ]

        if let videoComposition {
            let readerVideoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: videoTracks, videoSettings: outputSettings)
            readerVideoCompositionOutput.videoComposition = videoComposition
            readerOutput = readerVideoCompositionOutput
        } else {
            readerOutput = AVAssetReaderTrackOutput(track: firstVideoTrack, outputSettings: outputSettings)
        }
        return readerOutput
    }

    /// Creates video settings for configuring the writer input.
    private func buildOutputSettingsForAssetWriterInput(
        sourceVideoTrack: AVAssetTrack,
        compositorOutputsStereo: Bool
    ) async throws -> [String: Any]? {

        // Use an output settings assistant to avoid building the settings from scratch.
        let preset: AVOutputSettingsPreset = compositorOutputsStereo ? .mvhevc4320x4320 : .hevc1920x1080
        guard let outputSettings = AVOutputSettingsAssistant(preset: preset) else { return nil }

        let formatDescription = try await sourceVideoTrack.load(.formatDescriptions).first
        outputSettings.sourceVideoFormat = formatDescription

        guard var videoSettings = outputSettings.videoSettings else { return nil }
        
        let sourceSize = try await sourceVideoTrack.load(.naturalSize)
        let transform = try await sourceVideoTrack.load(.preferredTransform)
        let outputSize = sourceSize.applying(transform)
        videoSettings[AVVideoWidthKey] = abs(outputSize.width)
        videoSettings[AVVideoHeightKey] = abs(outputSize.height)

        // Special handling of video compression properties for stereo output video composition.
        if compositorOutputsStereo {
            if let formatExtensions = formatDescription?.extensions {
                // Create spatial video related compression session properties from the track format extensions.
                let compressionProperties = compressionSessionSpatialProperties(for: formatExtensions)
                
                // Merge with the existing properties populated by the output settings assistant to produce the full set of properties.
                if let existingCompressionSessionProperties = videoSettings[AVVideoCompressionPropertiesKey] as? [CFString: Any] {
                    videoSettings[AVVideoCompressionPropertiesKey] =
                        compressionProperties.merging(existingCompressionSessionProperties) {
                            (_, existing) in existing
                        }
                }
            }
        }
        return videoSettings
    }

    /// Mapping of spatial video related format extension keys to corresponding `VTCompressionSession` property keys used to configure video settings for writer input.
    private let formatExtensionSpatialKeyMapping = [
        kCMFormatDescriptionExtension_ProjectionKind: kVTCompressionPropertyKey_ProjectionKind,
        kCMFormatDescriptionExtension_StereoCameraBaseline: kVTCompressionPropertyKey_StereoCameraBaseline,
        kCMFormatDescriptionExtension_HorizontalFieldOfView: kVTCompressionPropertyKey_HorizontalFieldOfView,
        kCMFormatDescriptionExtension_HorizontalDisparityAdjustment: kVTCompressionPropertyKey_HorizontalDisparityAdjustment,
        kCMFormatDescriptionExtension_CameraCalibrationDataLensCollection: kVTCompressionPropertyKey_CameraCalibrationDataLensCollection,
        kCMFormatDescriptionExtension_HasLeftStereoEyeView: kVTCompressionPropertyKey_HasLeftStereoEyeView,
        kCMFormatDescriptionExtension_HasRightStereoEyeView: kVTCompressionPropertyKey_HasRightStereoEyeView
    ]

    /// Create spatial video related compression session properties from format extensions.
    private func compressionSessionSpatialProperties(for formatExtensions: CMFormatDescription.Extensions) -> [CFString: Any] {
        var compressionSessionProperties = [CFString: Any]()
        for (key, value) in formatExtensionSpatialKeyMapping {
            let compressionSessionPropertiesKey = value
            compressionSessionProperties[compressionSessionPropertiesKey] = formatExtensions[key]
        }
        return compressionSessionProperties
    }

    /// The main read-write loop of the exporter.
    private func performAssetReadingAndWriting(assetDuration: Double, tempURL: URL) async {
        guard let assetReader, let readerOutput, let assetWriter, let writerInput else { return }

        assetReader.startReading()
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)

        let taggedPixelBufferGroupReceiver = taggedBufferGroupReceiver

        // Create an `AsyncStream` for status updates.
        let (statusStream, statusContinuation) = AsyncStream.makeStream(of: ExporterStatus.self)

        // Start listening to status updates in a separate task.
        let statusTask = Task { @MainActor in
            for await newStatus in statusStream {
                status = newStatus
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in

            // Use `nonisolated(unsafe)` to opt out of `Sendable` checking for AVFoundation objects.
            // These objects are not marked as `Sendable`, but AVFoundation media processing APIs
            // are designed to be thread-safe for export operations like this, where the reader
            // and writer are used sequentially on a dedicated background queue.
            nonisolated(unsafe) let assetWriter = assetWriter
            nonisolated(unsafe) let writerInput = writerInput
            nonisolated(unsafe) let readerOutput = readerOutput

            // Helper function to finish writing and resume continuation.
            func finishWritingAndResume(error: ExportError? = nil) {
                writerInput.markAsFinished()
                assetWriter.finishWriting {
                    if let error {
                        logger.error("Export failure: \(error.rawValue)")
                        statusContinuation.yield(.failed(error))
                    } else {
                        statusContinuation.yield(.complete(outputURL: tempURL))
                    }
                    statusContinuation.finish()
                    continuation.resume()
                }
            }
            
            // The read-write loop is executed in a dedicated dispatch queue.
            writerInput.requestMediaDataWhenReady(on: DispatchQueue(label: "com.apple.spatialcompositor.reader")) {
                while writerInput.isReadyForMoreMediaData {

                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        // A nil sample buffer indicates the end of the input.
                        finishWritingAndResume()
                        return
                    }

                    if let taggedBuffers = sampleBuffer.taggedBuffers, let taggedPixelBufferGroupReceiver {
                        // Send tagged buffers to writer input via tagged pixel buffer group receiver.
                        // Make sure the tagged buffers are `CMTaggedDynamicBuffer` objects with `layerID` tags.
                        let wellFormedTaggedBuffers = taggedBuffers.ensureLayerIDTagsAndMakeDynamic(leftEyeLayer: 0, rightEyeLayer: 1)
                        do {
                            let pts = sampleBuffer.presentationTimeStamp
                            if try !taggedPixelBufferGroupReceiver.appendImmediately(wellFormedTaggedBuffers, with: pts) {
                                finishWritingAndResume(error: .appendTaggedBuffersFailed)
                                return
                            }
                        } catch {
                            finishWritingAndResume(error: .appendTaggedBuffersFailed)
                            return
                        }
                    } else {
                        // The reader output is a normal sample buffer. Send to writer input directly.
                        writerInput.append(sampleBuffer)
                    }
                    // Send async notification for progress update.
                    let percent = (Double) (sampleBuffer.presentationTimeStamp.seconds / assetDuration)
                    statusContinuation.yield(ExporterStatus.exporting(progress: percent))
                }
            }
        }

        // Wait for the status task to finish processing all status updates.
        await statusTask.value
    }
}

// MARK: taggedBuffers utilities
extension CMTaggedBuffer {
    /// Creates new `CMTaggedBuffer` by adding tags to the given `CMTaggedBuffer`.
    init(_ sourceTaggedBuffer: CMTaggedBuffer, addTags: [CMTag]?) {
        var newTags: [CMTag] = []
        newTags.append(contentsOf: sourceTaggedBuffer.tags)
        if let addTags {
            for tagToAdd in addTags {
                if !sourceTaggedBuffer.tags.contains(tagToAdd) {
                    newTags.append(tagToAdd)
                }
            }
        }

        self = CMTaggedBuffer(tags: newTags, buffer: sourceTaggedBuffer.buffer)
    }
}

extension Array where Element == CMTaggedBuffer {
    
    /// Creates `CMTaggedDynamicBuffer` objects suitable for asset writer input. The created tagged buffers have `layerID` tags.
    /// - Parameters
    ///   - leftEyeLayer: Layer ID for the left eye.
    ///   - rightEyeLayer: Layer ID for the right eye.
    func ensureLayerIDTagsAndMakeDynamic(leftEyeLayer: Int64, rightEyeLayer: Int64) -> [CMTaggedDynamicBuffer] {
        var newArray: [CMTaggedDynamicBuffer] = []
        for element in self {
            let newElement = if element.tags.contains(.stereoView(.leftEye)) {
                CMTaggedBuffer(element, addTags: [.videoLayerID(leftEyeLayer)])
            } else if element.tags.contains(.stereoView(.rightEye)) {
                CMTaggedBuffer(element, addTags: [.videoLayerID(rightEyeLayer)])
            } else {
                element
            }
            newArray.append(CMTaggedDynamicBuffer(unsafeBuffer: newElement))
        }
        return newArray
    }
}
