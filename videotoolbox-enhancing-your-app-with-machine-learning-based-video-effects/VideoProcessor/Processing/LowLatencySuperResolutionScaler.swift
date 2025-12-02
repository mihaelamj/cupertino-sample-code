/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `LowLatencySuperResolutionScaler`, which is a concrete
  implementation of `AsyncFrameProcessor` that increases the spatial resolution
  of video frames under low latency.
*/

import Foundation
@preconcurrency import VideoToolbox
import os

actor LowLatencySuperResolutionScaler: AsyncFrameProcessor {

    let scalar: Float
    let inputDimensions: CMVideoDimensions

    init(scalar: Float, inputDimensions: CMVideoDimensions) throws {

        self.scalar = scalar
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTLowLatencySuperResolutionScalerConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let maximumDimensions = VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions,
            width <= maximumDimensions.width,
            height <= maximumDimensions.height
        else {
            throw Fault.dimensionsTooLarge
        }

        guard let minimumDimensions = VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions,
            width >= minimumDimensions.width,
            height >= minimumDimensions.height
        else {
            throw Fault.dimensionsTooSmall
        }

        // Get supported scale factors.
        let supportedScaleFactors = VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: width, frameHeight: height)

        // Ensure input scale factor is supported.
        guard supportedScaleFactors
            .contains(where: { abs($0 - scalar) < 0.001 }) else {
            throw Fault.failedToCreateConfiguration
        }

        // Create configuration with validated scale factor.
        let configuration = VTLowLatencySuperResolutionScalerConfiguration(
            frameWidth: width,
            frameHeight: height,
            scaleFactor: scalar
        )

        self.configuration = configuration
        let destinationPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        pixelBufferPool = try Self.createPixelBufferPool(for: destinationPixelBufferAttributes)
        let sourcePixelBufferAttributes = configuration.sourcePixelBufferAttributes
        self.sourcePixelBufferAttributes = sourcePixelBufferAttributes
    }

    // Input and output streams from `AVAssetReader` and for `AVAssetWriter`.
    var inputStream: SampleBufferStream?
    var outputStreams: [SampleBufferStream] = []
    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any]

    let configuration: VTLowLatencySuperResolutionScalerConfiguration

    let pixelBufferPool: CVPixelBufferPool
    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()

    // This iterates across all of the input video frames and processes them.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard !outputStreams.isEmpty else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        // The processor may not be ready immediately after calling `startSession` due to model loading.
        // In real-time scenarios, avoid blocking critical tasks during `startSession` because it
        // may cause dropped or delayed frames.
        try frameProcessor.startSession(configuration: configuration)
        defer { frameProcessor.endSession() }

        for try await inputSampleBuffer in inputStream {
            
            let enhancedSampleBuffer = try await self.enhance(sourceSampleBuffer: inputSampleBuffer)

            try await send(enhancedSampleBuffer)
        }
    }
}

extension LowLatencySuperResolutionScaler {

    private func enhance(sourceSampleBuffer: SampleBuffer) async throws -> SampleBuffer {

        let sourcePTS = sourceSampleBuffer.presentationTimeStamp
        var sourceFrame: VTFrameProcessorFrame?
        if let pixelBuffer = sourceSampleBuffer.imageBuffer {
            sourceFrame = VTFrameProcessorFrame(buffer: pixelBuffer,
                                                presentationTimeStamp: sourcePTS)
        }
        guard let sourceFrame else { throw  Fault.missingImageBuffer }

        let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
        sourceSampleBuffer.propagateAttachments(to: pixelBuffer)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: pixelBuffer,
                                                           presentationTimeStamp: sourcePTS) else {
            throw Fault.missingImageBuffer
        }

        let parameters = VTLowLatencySuperResolutionScalerParameters(sourceFrame: sourceFrame,
                                                                     destinationFrame: destinationFrame)

        try await self.frameProcessor.process(parameters: parameters)

        sourceSampleBuffer.propagateAttachments(to: pixelBuffer)

        return try Self.createSampleBuffer(from: pixelBuffer, destinationFrame.presentationTimeStamp)
    }
}

func lowLatencySuperResolutionScalerMinimumDimensions() -> CMVideoDimensions? {

    return VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions
}

func lowLatencySuperResolutionScalerMaximumDimensions() -> CMVideoDimensions? {

    return VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions
}

