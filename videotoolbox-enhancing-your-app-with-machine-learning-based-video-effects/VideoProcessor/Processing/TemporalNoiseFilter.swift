/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `TemporalNoiseFilter`, which is a concrete implementation of
 `AsyncFrameProcessor` that removes noise artifacts from input video.
*/

import Foundation
@preconcurrency import VideoToolbox

// This is the implementation of `AsyncFrameProcessor` that performs
// the `VTTemporalNoiseFilter` process.
actor TemporalNoiseFilter: AsyncFrameProcessor {

    let strength: Float
    let inputDimensions: CMVideoDimensions

    init(strength: Float, inputDimensions: CMVideoDimensions) throws {
        self.strength = min(1.0, max(0, strength))
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTTemporalNoiseFilterConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let maximumDimensions = VTTemporalNoiseFilterConfiguration.maximumDimensions,
              width <= maximumDimensions.width,
              height <= maximumDimensions.height
        else {
            throw Fault.dimensionsTooLarge
        }

        guard let minimumDimensions = VTTemporalNoiseFilterConfiguration.minimumDimensions,
              width >= minimumDimensions.width,
              height >= minimumDimensions.height
        else {
            throw Fault.dimensionsTooSmall
        }

        // You can select a supported source pixel format from the
        // `VTTemporalNoiseFilterConfiguration.supportedSourcePixelFormats` list.
        let sourcePixelFormat = kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange
        if !VTTemporalNoiseFilterConfiguration.supportedSourcePixelFormats.contains(sourcePixelFormat) {
            throw Fault.unsupportedPixelFormat
        }

        guard let configuration = VTTemporalNoiseFilterConfiguration(frameWidth: width,
                                                                     frameHeight: height,
                                                                     sourcePixelFormat: sourcePixelFormat) else {
            throw Fault.failedToCreateConfiguration
        }

        self.configuration = configuration
        let sourcePixelBufferAttributes = configuration.sourcePixelBufferAttributes
        self.sourcePixelBufferAttributes = sourcePixelBufferAttributes

        let destinationPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        pixelBufferPool = try Self.createPixelBufferPool(for: destinationPixelBufferAttributes)
    }

    var inputStream: SampleBufferStream?
    var outputStreams: [SampleBufferStream] = []
    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any]

    let configuration: VTTemporalNoiseFilterConfiguration

    var pixelBufferPool: CVPixelBufferPool?
    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()

    // This iterates across all of the input video frames and processes them.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard outputStreams.isEmpty == false else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        try frameProcessor.startSession(configuration: configuration)
        defer { frameProcessor.endSession() }

        let maxPreviousFrameCount = configuration.previousFrameCount ?? 0
        let maxNextFrameCount = configuration.nextFrameCount ?? 0

        var previousSampleBuffers: [SampleBuffer] = []
        var nextSampleBuffers: [SampleBuffer] = []

        for try await inputSampleBuffer in inputStream {

            nextSampleBuffers.append(inputSampleBuffer)

            // This continues the loop if there aren't enough accumulated frames to start processing.
            if nextSampleBuffers.count <= maxNextFrameCount { continue }

            let currentSampleBuffer = nextSampleBuffers.removeFirst()

            // This calls the temporal noise filter and returns the processed frame.
            let convertedBuffer = try await convert(previousSampleBuffers: previousSampleBuffers,
                                                    currentSampleBuffer: currentSampleBuffer,
                                                    nextSampleBuffers: nextSampleBuffers)

            previousSampleBuffers.append(currentSampleBuffer)
            if previousSampleBuffers.count > maxPreviousFrameCount {
                previousSampleBuffers.removeFirst()
            }

            try await send(convertedBuffer)
        }

        // This processes the accumulated buffers.
        while nextSampleBuffers.isEmpty == false {

            let currentSampleBuffer = nextSampleBuffers.removeFirst()

            // This calls the temporal noise filter and returns the processed frame.
            let convertedBuffer = try await convert(previousSampleBuffers: previousSampleBuffers,
                                                    currentSampleBuffer: currentSampleBuffer,
                                                    nextSampleBuffers: nextSampleBuffers)

            previousSampleBuffers.append(currentSampleBuffer)
            if previousSampleBuffers.count > maxPreviousFrameCount {
                previousSampleBuffers.removeFirst()
            }

            try await send(convertedBuffer)
        }
    }
}

extension TemporalNoiseFilter {

    // This creates the `VTFrameProcessor` parameters and performs the actual noise reduction.
    private func convert(previousSampleBuffers: [SampleBuffer],
                         currentSampleBuffer: SampleBuffer,
                         nextSampleBuffers: [SampleBuffer]) async throws -> SampleBuffer {

        let currentPTS = currentSampleBuffer.presentationTimeStamp
        var currentFrame: VTFrameProcessorFrame?
        if let pixelBuffer = currentSampleBuffer.imageBuffer {
            currentFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: currentPTS)
        }
        guard let currentFrame else { throw Fault.missingImageBuffer }

        var previousFrames: [VTFrameProcessorFrame] = []
        for frame in previousSampleBuffers {
            guard let previousFrame = VTFrameProcessorFrame(buffer: frame.imageBuffer!,
                                                            presentationTimeStamp: frame.presentationTimeStamp) else {
                throw Fault.missingImageBuffer
            }
            previousFrames.append(previousFrame)
        }

        var nextFrames: [VTFrameProcessorFrame] = []
        for frame in nextSampleBuffers {
            guard let referenceFrame = VTFrameProcessorFrame(buffer: frame.imageBuffer!,
                                                             presentationTimeStamp: frame.presentationTimeStamp) else {
                throw Fault.missingImageBuffer
            }
            nextFrames.append(referenceFrame)
        }

        let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool!)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: currentPTS) else {
            throw Fault.missingImageBuffer
        }

        guard let parameters = VTTemporalNoiseFilterParameters(sourceFrame: currentFrame,
                                                               nextFrames: nextFrames,
                                                               previousFrames: previousFrames,
                                                               destinationFrame: destinationFrame,
                                                               filterStrength: strength,
                                                               hasDiscontinuity: false) else {
            throw Fault.failedToCreateParameters
        }

        try await frameProcessor.process(parameters: parameters)

        return try Self.createSampleBuffer(from: pixelBuffer, destinationFrame.presentationTimeStamp)
    }
}
