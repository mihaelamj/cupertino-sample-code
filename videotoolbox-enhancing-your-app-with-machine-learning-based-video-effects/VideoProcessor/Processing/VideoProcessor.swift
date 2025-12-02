/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VideoProcessor`, which
 processes the video file using `AsyncFrameProcessor`.
*/

import Foundation
import AVFoundation
import VideoToolbox
import OSLog
import AppKit

let logger = Logger()

@MainActor
@Observable
final class VideoProcessor {

    let model: VideoProcessorModel

    var aspectRatio = 1.0
    var inputPreviewStream: SampleBufferStream?
    var outputPreviewStream: SampleBufferStream?

    init(model: VideoProcessorModel) {
        self.model = model
    }
}

extension VideoProcessor {

    func setAspectRatio(_ ratio: Double) {
        aspectRatio = ratio
    }

    func setInputPreviewStream(_ stream: SampleBufferStream) {
        inputPreviewStream = stream
    }

    func setOutputPreviewStream(_ stream: SampleBufferStream) {
        outputPreviewStream = stream
    }
}

extension VideoProcessor {

    func startProcessing(effect: VideoEffect) {

        guard case .ready(let inputURL) = model.state else { return }

        let outputURL = temporaryOutputURL
        try? FileManager.default.removeItem(at: outputURL)

        Task.detached { [self] in

            do {
                try await processVideo(effect: effect, inputURL: inputURL, outputURL: outputURL)

            } catch {

                logger.error("### \(effect) failed with error: \(error) ###")
                await model.setState(.failed(error: error))
            }
        }
    }
}

extension VideoProcessor {

    // Specify the processing destination URL.
    nonisolated var temporaryOutputURL: URL {

        let fileManager = FileManager.default

        let tempDirectoryURL = fileManager.temporaryDirectory

        let outputFileName = "VideoEffectOutput.mov"

        return tempDirectoryURL.appendingPathComponent(outputFileName)
    }
}

extension VideoProcessor {
    enum Fault: Error {
        case effectNotSupported

    }
}
extension VideoProcessor {

    // Create the specified `AsyncFrameProcessor`.
    func createAsyncFrameProcessor(for videoEffect: VideoEffect,
                                   with dimensions: CMVideoDimensions) throws -> AsyncFrameProcessor {
        switch videoEffect {

        case .frameRateConversion:

            let frameRateMultiplier = model.frcMultiplier
            return try FrameRateConversionProcessor(multiplier: Int(frameRateMultiplier),
                                                    inputDimensions: dimensions)

        case .motionBlur:
            let blurStrength = model.blurStrength
            return try MotionBlurProcessor(strength: Int(blurStrength),
                                           inputDimensions: dimensions)
        case .superResolutionScaler:
            let scaleFactor = model.srsScaleFactor
            return try SuperResolutionScaler(scaleFactor: Int(scaleFactor),
                                             inputDimensions: dimensions)
        case .temporalNoiseFilter:
            let filterStrength = model.noiseFilterStrength
            return try TemporalNoiseFilter(strength: Float(filterStrength),
                                           inputDimensions: dimensions)

        case .lowLatencyFrameInterpolation:
            let llfiNumFramesBetween = model.llfiNumFramesBetween
            let llfiScalarMultiplier = model.llfiScalarMultiplier
            return try LowLatencyFrameInterpolation(numFrames: Int(llfiNumFramesBetween),
                                                    scalar: Int(llfiScalarMultiplier),
                                                    inputDimensions: dimensions)
        case .lowLatencySuperResolutionScaler:
            let llsrsScalar = model.llsrsScaleFactor
            return try LowLatencySuperResolutionScaler(scalar: llsrsScalar,
                                                       inputDimensions: dimensions)
        }
    }
}

extension VideoProcessor {

    // Process the file using the appropriate frame processor.
    // Note that this is nonisolated because you don't want it to run on the main actor.
    nonisolated func processVideo(effect: VideoEffect, inputURL: URL, outputURL: URL) async throws {

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in

            let assetReader = AsyncAssetReader(inputURL: inputURL)

            let dimensions = try await assetReader.videoTrackDimensions()
            await setAspectRatio(Double(dimensions.width) / Double(dimensions.height))

            // Create `FrameProcessor`.
            let frameProcessor = try await createAsyncFrameProcessor(for: effect,
                                                                     with: dimensions)

            nonisolated(unsafe) let sourcePixelBufferAttributes = frameProcessor.sourcePixelBufferAttributes

            // Configure `AsyncAssetReader` to provide the input `SampleBufferStream`.
            try await assetReader.configure(sourcePixelBufferAttributes: sourcePixelBufferAttributes)
            let assetReaderOutputStream = try await assetReader.outputStream()
            let inputPreviewStream = try await assetReader.outputStream(bufferingPolicy: .waitAfterBuffering(2))
            await self.setInputPreviewStream(inputPreviewStream)
            let progressStream = try await assetReader.progressStream()

            let verifyBuffer = try VerifyBufferAttributes(pixelBufferAttributes: sourcePixelBufferAttributes)
            try await verifyBuffer.setInputStream(assetReaderOutputStream)
            let verifyBufferOutputStream = try await verifyBuffer.outputStream()

            // Set up `FrameProcessor` to process the input `SampleBufferStream`.
            try await frameProcessor.setInputStream(verifyBufferOutputStream)
            let frameProcessorOutputStream = try await frameProcessor.outputStream()
            let outputPreviewStream = try await frameProcessor.outputStream(bufferingPolicy: .waitAfterBuffering(1))
            await setOutputPreviewStream(outputPreviewStream)

            // Create `AsyncAssetWriter` to write the output `SampleBufferStream` to disk.
            let assetWriter = AsyncAssetWriter(outputURL: outputURL)
            try await assetWriter.setInputStream(frameProcessorOutputStream)

            // This creates the `taskGroup` tasks that do the actual work.
            taskGroup.addTask { try await assetReader.run() }

            taskGroup.addTask { try await verifyBuffer.run() }

            taskGroup.addTask { try await frameProcessor.run() }

            taskGroup.addTask { try await assetWriter.run() }

            taskGroup.addTask { [model] in
                // Update the progress state in the model for the
                // progress indicator.
                for try await progress in progressStream {
                    await model.setState(.processing(progress: max(0.0, min(1.0, progress))))
                }
            }

            // This causes exceptions to immediately propagate.
            try await taskGroup.next()

            // Wait until all the work is complete.
            try await taskGroup.waitForAll()

            // Give everything a chance to clean up.
            await assetReader.finish()
            await frameProcessor.finish()
            await assetWriter.finish()

            await model.setState(.completed(outputURL: outputURL))
        }
    }
}
