/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `MotionBlurProcessor`, which is a concrete implementation of
 `AsyncFrameProcessor` that blurs regions of the frames that contain motion.
*/

import Foundation
@preconcurrency import VideoToolbox

// This is the implementation of `AsyncFrameProcessor` that performs
// the `VTMotionBlur` process.

//When creating a `VTMotionBlurConfiguration` object, you need to make some
//important design decisions that impact how you set up your session.
//`usePrecomputedFlow` parameter: If possible, compute optical flow
//offline beforehand using `VTFrameOpticalFlowConfiguration` and save
//it to disk. This makes the frame interpolation run faster because
//optical flow is already computed. Set `usePrecomputedFlow` to `true` to
//indicate this. If you set `usePrecomputedFlow` to `false`, optical flow
//computes during motion blur.
//`qualityPrioritization` parameter: Normal mode is the recommended setting
//in most instances. If performance isn't a concern, use the quality mode.
//`revision` parameter: For the revision, there are two choices --- either
//statically set a revision to stay on the same algorithm until it's
//deprecated, or use `defaultRevision` property to
//use the latest recommended algorithm.

actor MotionBlurProcessor: AsyncFrameProcessor {

    let strength: Int
    let inputDimensions: CMVideoDimensions

    init(strength: Int, inputDimensions: CMVideoDimensions) throws {

        self.strength = min(100, max(1, strength))
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTMotionBlurConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let configuration = VTMotionBlurConfiguration(frameWidth: width,
                                                            frameHeight: height,
                                                            usePrecomputedFlow: false,
                                                            qualityPrioritization: .normal,
                                                            revision: .revision1) else {
            throw Fault.failedToCreateBlurConfiguration
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

    let configuration: VTMotionBlurConfiguration

    let pixelBufferPool: CVPixelBufferPool
    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()

    // This iterates across all of the input video frames and processes them.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard outputStreams.isEmpty == false else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        try frameProcessor.startSession(configuration: configuration)
        defer { frameProcessor.endSession() }

        var previousSampleBuffer: SampleBuffer?
        var currentSampleBuffer: SampleBuffer?
        var nextSampleBuffer: SampleBuffer?

        for try await inputSampleBuffer in inputStream {

            // This maintains at least two, and up to three, consecutive
            // sample buffers.
            previousSampleBuffer = currentSampleBuffer
            currentSampleBuffer = nextSampleBuffer
            nextSampleBuffer = inputSampleBuffer

            // This continues the loop if there aren't at least two accumulated buffers.
            guard let currentSampleBuffer else { continue } // The first buffer is not ready.

            // This calls the motion blur, which returns the processed frame.
            let convertedBuffer = try await convert(previousSampleBuffer: previousSampleBuffer,
                                                    currentSampleBuffer: currentSampleBuffer,
                                                    nextSampleBuffer: nextSampleBuffer)

            try await send(convertedBuffer)
        }

        // This processes the final sample buffer.
        if let currentSampleBuffer = nextSampleBuffer {
            let convertedBuffer = try await convert(previousSampleBuffer: previousSampleBuffer,
                                                    currentSampleBuffer: currentSampleBuffer,
                                                    nextSampleBuffer: nil)

            try await send(convertedBuffer)
        }
    }
}

extension MotionBlurProcessor {

    // This creates the `VTFrameProcessor` parameters and performs the actual motion blur.
    private func convert(previousSampleBuffer: SampleBuffer?,
                         currentSampleBuffer: SampleBuffer,
                         nextSampleBuffer: SampleBuffer?) async throws -> SampleBuffer {

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

        var nextFrame: VTFrameProcessorFrame?
        if let nextSampleBuffer,
           let pixelBuffer = nextSampleBuffer.imageBuffer {
            nextFrame = VTFrameProcessorFrame(buffer: pixelBuffer,
                                              presentationTimeStamp: nextSampleBuffer.presentationTimeStamp)
        }

        let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: currentPTS) else {
            throw Fault.missingImageBuffer
        }

        // It's important to set `submissionMode` to `.random` if you're not
        // submitting the frames in sequential presentation time order.
        guard let parameters = VTMotionBlurParameters(sourceFrame: currentFrame,
                                                      nextFrame: nextFrame,
                                                      previousFrame: previousFrame,
                                                      nextOpticalFlow: nil,
                                                      previousOpticalFlow: nil,
                                                      motionBlurStrength: strength,
                                                      submissionMode: .sequential,
                                                      destinationFrame: destinationFrame) else {
            throw Fault.failedToCreateMotionBlurParameters
        }

        try await frameProcessor.process(parameters: parameters)

        return try Self.createSampleBuffer(from: pixelBuffer, destinationFrame.presentationTimeStamp)
    }
}

