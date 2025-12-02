/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `SuperResolutionScaler`, which is a concrete implementation of
 `AsyncFrameProcessor` that increases the spatial resolution of the video frames.
*/

import Foundation
@preconcurrency import VideoToolbox
import OSLog

// This is the implementation of `AsyncFrameProcessor` that performs
// the `VTSuperResolutionScaler` process.
actor SuperResolutionScaler: AsyncFrameProcessor {

    let scaleFactor: Int
    let inputDimensions: CMVideoDimensions

    init(scaleFactor: Int, inputDimensions: CMVideoDimensions) throws {

        self.scaleFactor = scaleFactor
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTSuperResolutionScalerConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let configuration = VTSuperResolutionScalerConfiguration(frameWidth: width,
                                                                       frameHeight: height,
                                                                       scaleFactor: scaleFactor,
                                                                       inputType: .video,
                                                                       usePrecomputedFlow: false,
                                                                       qualityPrioritization: .normal,
                                                                       revision: .revision1) else {
            throw Fault.failedToCreateSRSConfiguration
        }

        self.configuration = configuration
        let destinationPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        pixelBufferPool = try Self.createPixelBufferPool(for: destinationPixelBufferAttributes)
        let sourcePixelBufferAttributes = configuration.sourcePixelBufferAttributes
        self.sourcePixelBufferAttributes = sourcePixelBufferAttributes
    }

    var inputStream: SampleBufferStream?
    var outputStreams: [SampleBufferStream] = []
    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any]

    let configuration: VTSuperResolutionScalerConfiguration

    let pixelBufferPool: CVPixelBufferPool
    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()
    var previousOutputFrame: VTFrameProcessorFrame?

    // This iterates across all of the input video frames and processes them.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard outputStreams.isEmpty == false else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        let downloadResult: Error? = await withCheckedContinuation { continuation in
            configuration.downloadConfigurationModel() { status in
                continuation.resume(returning: status)
            }
        }
        guard downloadResult == nil else {
            throw Fault.failedToDownloadModel
        }

        try frameProcessor.startSession(configuration: configuration)
        defer { frameProcessor.endSession() }

        var previousSampleBuffer: SampleBuffer?
        var currentSampleBuffer: SampleBuffer?

        previousOutputFrame = nil

        for try await inputSampleBuffer in inputStream {

            // This maintains at least two, and up to three, consecutive
            // sample buffers.
            previousSampleBuffer = currentSampleBuffer
            currentSampleBuffer = inputSampleBuffer

            // This calls the super-resolution scaler, which returns the
            // processed frame.
            let convertedBuffer = try await convert(previousSampleBuffer: previousSampleBuffer,
                                                    currentSampleBuffer: currentSampleBuffer!)

            try await send(convertedBuffer)
        }
    }
}

extension SuperResolutionScaler {

    // This creates the `VTFrameProcessor` parameters and performs the actual scale.
    private func convert(previousSampleBuffer: SampleBuffer?,
                         currentSampleBuffer: SampleBuffer) async throws -> SampleBuffer {

        let currentPTS = currentSampleBuffer.presentationTimeStamp
        var currentFrame: VTFrameProcessorFrame?
        if let pixelBuffer = currentSampleBuffer.imageBuffer {
            currentFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: currentPTS)
        }
        guard let currentFrame else { throw Fault.missingImageBuffer }

        var previousFrame: VTFrameProcessorFrame?
        if let previousSampleBuffer,
           let pixelBuffer = previousSampleBuffer.imageBuffer {
            previousFrame = VTFrameProcessorFrame(buffer: pixelBuffer,
                                                  presentationTimeStamp: previousSampleBuffer.presentationTimeStamp)
        }

        let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: currentPTS) else {
            throw Fault.missingImageBuffer
        }

        guard let parameters = VTSuperResolutionScalerParameters(sourceFrame: currentFrame,
                                                                 previousFrame: previousFrame,
                                                                 previousOutputFrame: previousOutputFrame,
                                                                 opticalFlow: nil,
                                                                 submissionMode: .sequential ,
                                                                 destinationFrame: destinationFrame) else {
            throw Fault.failedToCreateSRSParameters
        }
        previousOutputFrame = destinationFrame

        try await frameProcessor.process(parameters: parameters)

        return try Self.createSampleBuffer(from: pixelBuffer, destinationFrame.presentationTimeStamp)
    }
}

func superResolutionScaleFactors() -> [Int] {
    return VTSuperResolutionScalerConfiguration.supportedScaleFactors
}
