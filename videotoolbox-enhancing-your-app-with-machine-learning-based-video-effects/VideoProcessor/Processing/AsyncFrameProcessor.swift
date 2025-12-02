/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the `AsyncFrameProcessor` protocol.
*/

import Foundation
import AVFoundation
@preconcurrency import VideoToolbox

// The `AsyncFrameProcessor` protocol defines the structure that allows
// multiple `VTFrameProcessor` instances to concurrently operate on sequential frames without having
// to deal with the complexity of streaming.

protocol AsyncFrameProcessor: Actor {

    typealias Fault = AsyncFrameProcessorFault
    typealias BufferingPolicy = `SampleBufferStream`.BufferingPolicy

    // This returns the processed result output `SampleBufferStream`.
    func outputStream(bufferingPolicy: BufferingPolicy) async throws -> SampleBufferStream

    // This supplies the input `SampleBufferStream` of frames to process.
    func setInputStream(_ sampleBufferStream: SampleBufferStream) async throws

    // Start processing the video frames.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws

    // Stop processing the video frames and perform any necessary cleanup.
    func finish()

    var inputStream: SampleBufferStream? { get set }
    var outputStreams: [SampleBufferStream] { get set }
    nonisolated var sourcePixelBufferAttributes: [String: Any] { get }
}

// This provides common implementations of `setInputStream` and
// `outputStream` send and finish.
extension AsyncFrameProcessor {

    func setInputStream(_ sampleBufferStream: SampleBufferStream) async throws {

        guard inputStream == nil else { throw Fault.overSubscribed }

        inputStream = sampleBufferStream
    }

    func outputStream(bufferingPolicy: BufferingPolicy = .waitAfterBuffering(2))  async throws -> SampleBufferStream {

        let stream = SampleBufferStream(bufferingPolicy: bufferingPolicy)
        outputStreams.append(stream)
        return stream
    }

    func send(_ sampleBuffer: SampleBuffer) async throws {
        for stream in outputStreams {
            try await stream.send(sampleBuffer)
        }
    }

    func finish() {
        inputStream?.finish()
        inputStream = nil
        for stream in outputStreams {
            stream.finish()
        }
        outputStreams.removeAll()
    }
}

// This provides common implementations of `createPixelBufferPool`,
// `createSampleBuffer`, and `createPixelBuffer`.
extension AsyncFrameProcessor {

    // This creates `CVPixelBufferPool` to supply for the processed output frames.
    static func createPixelBufferPool(for sampleBuffer: SampleBuffer,
                                      count: Int = 2) throws -> CVPixelBufferPool {

        guard let formatDescription = sampleBuffer.formatDescription else {
            throw Fault.missingFormatDescription
        }

        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: formatDescription.mediaSubType.rawValue,
            kCVPixelBufferWidthKey as String: formatDescription.dimensions.width,
            kCVPixelBufferHeightKey as String: formatDescription.dimensions.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        return try createPixelBufferPool(for: pixelBufferAttributes,
                                               count: count)
    }

    // This creates `CVPixelBufferPool` to supply for the processed output frames.
    static func createPixelBufferPool(for pixelBufferAttributes: [String: Any],
                                      count: Int = 2) throws -> CVPixelBufferPool {

        let pixelBufferPoolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: count]

        var pixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                pixelBufferPoolAttributes as NSDictionary?,
                                pixelBufferAttributes as NSDictionary?,
                                &pixelBufferPool)

        guard let pixelBufferPool else { throw Fault.failedToCreatePixelBufferPool }

        return pixelBufferPool
    }

    // This creates a `CMSampleBuffer` for the provided `CVPixelBuffer`.
    static func createSampleBuffer(from pixelBuffer: CVPixelBuffer,
                                   _ timestamp: CMTime) throws -> SampleBuffer {

        let formatDescription = try CMFormatDescription(imageBuffer: pixelBuffer)

        let timingInfo = CMSampleTimingInfo(duration: .invalid,
                                            presentationTimeStamp: timestamp,
                                            decodeTimeStamp: .invalid)

        let cmSampleBuffer = try CMSampleBuffer(imageBuffer: pixelBuffer,
                                                formatDescription: formatDescription,
                                                sampleTiming: timingInfo)

        pixelBuffer.propagateAttachments(to: cmSampleBuffer)
        return SampleBuffer(wrapping: cmSampleBuffer)
    }

    // This creates `CVPixelBuffer` from the provided `CVPixelBufferPool`.
    static func createPixelBuffer(from pixelBufferPool: CVPixelBufferPool) throws -> CVPixelBuffer {

        var outputPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                            pixelBufferPool,
                                            &outputPixelBuffer)
        guard let outputPixelBuffer else {
            throw Fault.failedToCreatePixelBuffer
        }

        return outputPixelBuffer
    }
}

enum AsyncFrameProcessorFault: Error {

    case unsupportedProcessor
    case missingFormatDescription
    case failedToCreatePixelBuffer
    case failedToCreatePixelBufferPool
    case failedToPerformPixelTransfer
    case allocationFailed
    case overSubscribed
    case missingSampleBufferStream
    case failedToCreateFRCConfiguration
    case failedToCreateBlurConfiguration
    case failedToCreateSRSConfiguration
    case failedToCreateNoiseFilterConfiguration
    case failedToCreateTransferSession
    case failedToCreateConfiguration
    case failedToCreateParameters
    case missingImageBuffer
    case failedToCreateFRCParameters
    case failedToCreateMotionBlurParameters
    case failedToCreateSRSParameters
    case failedToDownloadModel
    case failedToCopyAttributes
    case dimensionsTooLarge
    case dimensionsTooSmall
    case unsupportedPixelFormat
}
