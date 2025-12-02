/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A concrete implementation of `AsyncFrameProcessor` that does low-latency frame-rate
 conversion, as well as low-latency scalar and interpolation.
*/

import Foundation
@preconcurrency import VideoToolbox
import OSLog

// This is the implementation of `AsyncFrameProcessor` that performs
// the `VTLowLatencyFrameInterpolation` process.

//`VTLowLatencyFrameInterpolationConfiguration` can either scale and interpolate your frames
// to double the resolution and double the number of frames, or only increase the number of
// frames. The number of frames you can interpolate within real-time constraint is dependent on
// device capabilities.

actor LowLatencyFrameInterpolation: AsyncFrameProcessor {

    let numFrames: Int
    let scalar: Int
    let inputDimensions: CMVideoDimensions

    init(numFrames: Int, scalar: Int, inputDimensions: CMVideoDimensions) throws {
        self.scalar = scalar
        self.numFrames = scalar == 2 ? 1 : min(3, numFrames)
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTLowLatencyFrameInterpolationConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let configuration = switch scalar {
        case 1:
            VTLowLatencyFrameInterpolationConfiguration(frameWidth: width,
                                                        frameHeight: height,
                                                        numberOfInterpolatedFrames: numFrames)
        default:
            VTLowLatencyFrameInterpolationConfiguration(frameWidth: width,
                                                        frameHeight: height,
                                                        spatialScaleFactor: scalar)
        } else {
            throw Fault.failedToCreateConfiguration
        }
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

    let configuration: VTLowLatencyFrameInterpolationConfiguration

    let pixelBufferPool: CVPixelBufferPool
    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()

    // This iterates across all of the input video frames and processes them.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard !outputStreams.isEmpty else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        // The processor may not be ready immediately after calling `startSession` due to model loading.
        // In real-time scenarios, avoid blocking critical tasks during `startSession` because
        // it may cause dropped or delayed frames.
        try frameProcessor.startSession(configuration: configuration)
        defer { frameProcessor.endSession() }

        var sourceSampleBuffer: SampleBuffer?
        var nextSampleBuffer: SampleBuffer?

        for try await inputSampleBuffer in inputStream {

            // This maintains two consecutive sample buffers.
            sourceSampleBuffer = nextSampleBuffer
            nextSampleBuffer = inputSampleBuffer

            // This continues the loop if there aren't two accumulated buffers.
            guard let sourceSampleBuffer,
                  let nextSampleBuffer else { continue } // The first buffer isn't ready.

            try await self.interpolate(sourceSampleBuffer: sourceSampleBuffer,
                                       nextSampleBuffer: nextSampleBuffer)

        }
    }
}

extension LowLatencyFrameInterpolation {
    private func interpolate(sourceSampleBuffer: SampleBuffer,
                             nextSampleBuffer: SampleBuffer) async throws {

        // This creates `VTFrameProcessorFrame` for the source frame.
        let sourcePTS = sourceSampleBuffer.presentationTimeStamp
        var sourceFrame: VTFrameProcessorFrame?
        if let pixelBuffer = sourceSampleBuffer.imageBuffer {
            sourceFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: sourcePTS)
        }
        guard let sourceFrame else { throw  Fault.missingImageBuffer }

        // This creates `VTFrameProcessorFrame` for the next frame.
        let nextPTS = nextSampleBuffer.presentationTimeStamp
        var nextFrame: VTFrameProcessorFrame?
        if let pixelBuffer = nextSampleBuffer.imageBuffer {
            nextFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: nextPTS)
        }
        guard let nextFrame else { throw Fault.missingImageBuffer }

        // This creates the interpolation phase array and the destination buffers.
        let intervals = interpolationIntervals()
        let destinationFrames = try framesBetween(firstPTS: sourcePTS,
                                                  lastPTS: nextPTS,
                                                  interpolationIntervals: intervals)

        let intervalArray = intervals.map { Float($0) }

        guard let parameters = VTLowLatencyFrameInterpolationParameters(sourceFrame: nextFrame,
                                                                        previousFrame: sourceFrame,
                                                                        interpolationPhase: intervalArray,
                                                                        destinationFrames: destinationFrames) else {
            throw Fault.failedToCreateParameters
        }
        // Send the original video's frame if you're only interpolating.
        if scalar == 1 {
            try await send(sourceSampleBuffer)
        }

        // This filter can use progressive callback if you want the next processed frame as soon as it's ready.
        // This is useful when generating a lot of interpolated frames so that the next frame
        // doesn't need to wait for processing to completely finish before the system displays it.
        // The resulting output frames are `CVReadOnlyPixelBuffer`, so you can use the unsafe buffer
        // `result.frame.withUnsafeBuffer(\.self)` if the app doesn't support `CMReadySampleBuffer`.
        for try await readOnlyFrame in frameProcessor.process(parameters: parameters) {

            let newSampleBuffer = try readOnlyFrame.frame.withUnsafeBuffer { pixelBuffer in

                return try Self.createSampleBuffer(from: pixelBuffer,
                                                   readOnlyFrame.timeStamp)
            }
            try await send(newSampleBuffer)
        }
    }

    // This creates an array of `Double` values between `0.0` and `1.0`, one for each
    // new frame to create. The system interpolates the new frames at the denoted
    // interval between the source and the next frame.
    private func interpolationIntervals() -> [Double] {
        let  interpolationInterval = 1.0 / (Double(numFrames) + 1)
        return Array(stride(from: interpolationInterval, through: 1.0, by: interpolationInterval).dropLast())
    }

    // This creates an array of pixel buffers, one for each new frame, and
    // sets the presentation timestamp at the appropriate time.
    private func framesBetween(firstPTS: CMTime, lastPTS: CMTime,
                               interpolationIntervals: [Double]) throws -> [VTFrameProcessorFrame] {

        let ptsRange = Double(CMTimeGetSeconds(lastPTS) - CMTimeGetSeconds(firstPTS))
        let ptsScale = lastPTS.timescale

        var interpolationFrames: [VTFrameProcessorFrame] = []
        if scalar == 2 {
            // Because the system doesn't scale the first frame it sends, the video starts on the
            // first interpolated frame. Therefore, its `pts` is the same as `firstPTS`.
            let pts = CMTime(seconds: CMTimeGetSeconds(firstPTS), preferredTimescale: ptsScale)
            let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
            let interpolationFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: pts)
            interpolationFrames.append(interpolationFrame!)
        }

        // Calculate the expected `pts` based on the interpolation intervals the system creates,
        // and create a sample buffer for each.
        for interpolationInterval in interpolationIntervals {
            let ptsValue = ptsRange * interpolationInterval
            let pts = CMTime(seconds: ptsValue + CMTimeGetSeconds(firstPTS), preferredTimescale: ptsScale)
            let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
            let interpolationFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: pts)
            interpolationFrames.append(interpolationFrame!)
        }
        return interpolationFrames
    }
}
