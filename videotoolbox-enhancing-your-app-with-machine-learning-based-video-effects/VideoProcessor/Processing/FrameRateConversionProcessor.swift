/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `FrameRateConversionProcessor`, which is a concrete implementation of
 `AsyncFrameProcessor` that creates interpolated frames between the input video
 frames, and sends the higher frame rate output to the output `SampleBufferStream`.
*/

import Foundation
@preconcurrency import VideoToolbox

// This is the implementation of `AsyncFrameProcessor` that performs
// the `VTFrameRateConversionParameters` process.

// When creating a `VTFrameRateConversionConfiguration` object, you
// need to make some important design decisions that impact how you
// set up your session.
// `usePrecomputedFlow` parameter: If possible, compute optical flow
// offline beforehand using `VTFrameOpticalFlowConfiguration` and save
// it to disk. This makes the frame interpolation run faster because
// optical flow is already computed. Set `usePrecomputedFlow` to `true` to
// indicate this. If you set `usePrecomputedFlow` to `false`, optical flow
// computes during frame interpolation.
// `qualityPrioritization` parameter: Normal mode is the recommended setting
// for most instances. If performance isn't a concern, use the quality
// mode.
// `revision` parameter: For the revision, there are two choices --- either
// statically set a revision to stay on the same algorithm until it's
// deprecated, or use `defaultRevision` property to
// use the latest recommended algorithm.

actor FrameRateConversionProcessor: AsyncFrameProcessor {

    let multiplier: Int
    let inputDimensions: CMVideoDimensions

    init(multiplier: Int, inputDimensions: CMVideoDimensions) throws {
        self.multiplier = min(8, max(2, multiplier))
        self.inputDimensions = inputDimensions

        let width = Int(inputDimensions.width)
        let height = Int(inputDimensions.height)

        guard VTFrameRateConversionConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let configuration = VTFrameRateConversionConfiguration(frameWidth: width,
                                                                     frameHeight: height,
                                                                     usePrecomputedFlow: false,
                                                                     qualityPrioritization: .normal,
                                                                     revision: .revision1) else {
            throw Fault.failedToCreateFRCConfiguration
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

    let configuration: VTFrameRateConversionConfiguration

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

        var sourceSampleBuffer: SampleBuffer?
        var nextSampleBuffer: SampleBuffer?

        for try await inputSampleBuffer in inputStream {

            // This maintains two consecutive sample buffers.
            sourceSampleBuffer = nextSampleBuffer
            nextSampleBuffer = inputSampleBuffer

            // This continues the loop if there aren't two accumulated buffers.
            guard let sourceSampleBuffer,
                  let nextSampleBuffer else { continue } // The first buffer is not ready.

            // This calls the frame-rate conversion, which returns an array
            // of sample buffers containing `sourceSampleBuffer` and the
            // newly created buffers.
            let convertedBuffers = try await convert(sourceSampleBuffer: sourceSampleBuffer,
                                                     nextSampleBuffer: nextSampleBuffer)

            for convertedBuffer in convertedBuffers {
                try await send(convertedBuffer)
            }
        }
        // This sends the final sample buffer.
        if let nextSampleBuffer {
            try await send(nextSampleBuffer)
        }
    }
}

extension FrameRateConversionProcessor {

    // This creates `VTFrameProcessor` parameters and performs the actual
    // frame-rate conversion.
    func convert(sourceSampleBuffer: SampleBuffer,
                 nextSampleBuffer: SampleBuffer) async throws -> [SampleBuffer] {
        // When creating a `VTFrameRateConversionParameters` object, you need to make
        // some important design decisions that impact how you send your frames.
        // For example, in a 4x slow motion scenario, you might want to interpolate
        // three frames at equal intervals (`.25, .5, .75`) between the
        // current source frame and the next source frame. You can interpolate all
        // three frames at once, but you need to allocate all
        // of the destination frames and wait for all frames to complete.
        // You can also call the process function multiple times, one for each
        // interpolated frame. In this case, you can use the `submissionMode` parameter
        // to optimize performance as follows:
        //   First, process call `sourceFrame:FrameO nextFrame:Frame1
        //     intervalArray:{0.25} submissionMode:.sequential`.
        //   Second, process call `sourceFrame:FrameO nextFrame:Frame1
        //     intervalArray:{0.5} submissionMode:.sequentialReferencesUnchanged`.
        //   Third, process call `sourceFrame:FrameO nextFrame:Frame1
        //     intervalArray:{0.75} `submissionMode:.sequentialReferencesUnchanged`.
        //   Fourth, process call `sourceFrame:Frame1 nextFrame:Frame2
        //     intervalArray:{0.25} submissionMode:.sequential`.
        // Note that in all cases, if a jump in a clip happens, you need to set
        // `submissionMode` to `random`.

        let sourcePTS = sourceSampleBuffer.presentationTimeStamp
        var sourceFrame: VTFrameProcessorFrame?
        if let pixelBuffer = sourceSampleBuffer.imageBuffer {
            sourceFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: sourcePTS)
        }
        guard let sourceFrame else { throw Fault.missingImageBuffer }

        let nextPTS = nextSampleBuffer.presentationTimeStamp
        var nextFrame: VTFrameProcessorFrame?
        if let pixelBuffer = nextSampleBuffer.imageBuffer {
            nextFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: nextPTS)
        }
        guard let nextFrame else { throw Fault.missingImageBuffer }

        let intervals = interpolationIntervals()

        let destinationFrames = try framesBetween(firstPTS: sourcePTS,
                                                   lastPTS: nextPTS,
                                                   interpolationIntervals: intervals)

        let intervalArray = intervals.map { Float($0) }

        guard let parameters = VTFrameRateConversionParameters(sourceFrame: sourceFrame,
                                                               nextFrame: nextFrame,
                                                               opticalFlow: nil,
                                                               interpolationPhase: intervalArray,
                                                               submissionMode: .sequential,
                                                               destinationFrames: destinationFrames) else {
            throw Fault.failedToCreateFRCParameters
        }

        try await frameProcessor.process(parameters: parameters)

        var sampleBuffers = [sourceSampleBuffer]

        let newSampleBuffers = try destinationFrames.map { veFrame in

            sourceSampleBuffer.propagateAttachments(to: veFrame.buffer)
            return try Self.createSampleBuffer(from: veFrame.buffer,
                                               veFrame.presentationTimeStamp)
        }
        sampleBuffers.append(contentsOf: newSampleBuffers)

        return sampleBuffers
    }

    // This creates an array of `Double` values between `0.0` and `1.0`, one for each
    // new frame to create. The system interpolates new frames at the denoted
    // interval between the source and the next frame.
    private func interpolationIntervals() -> [Double] {
        let  interpolationInterval = 1.0 / Double(multiplier)
        return Array(stride(from: interpolationInterval, through: 1.0, by: interpolationInterval).dropLast())
    }

    // This creates an array of pixel buffers, one for each new frame, and
    // sets the presentation timestamp at the appropriate time.
    private func framesBetween(firstPTS: CMTime, lastPTS: CMTime,
                               interpolationIntervals: [Double]) throws -> [VTFrameProcessorFrame] {

        let ptsRange = Double(lastPTS.value - firstPTS.value)
        let ptsScale = firstPTS.timescale

        var veFrames: [VTFrameProcessorFrame] = []

        for interpolationInterval in interpolationIntervals {
            let ptsValue = ptsRange * interpolationInterval
            let pts = CMTime(value: CMTimeValue(ptsValue) + firstPTS.value, timescale: ptsScale)
            let pixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)
            let veFrame = VTFrameProcessorFrame(buffer: pixelBuffer, presentationTimeStamp: pts)
            veFrames.append(veFrame!)
        }
        return veFrames
    }
}

