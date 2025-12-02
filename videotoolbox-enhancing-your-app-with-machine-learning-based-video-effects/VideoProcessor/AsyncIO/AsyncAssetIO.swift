/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `AsyncAssetReader` and `AsyncAssetWriter`, which create a simple wrapper
  around `AVAssetWriter` and `AVAssetReader` to provide an `AsyncIOStream` interface.
*/

import Foundation
import AVFoundation

// `SampleBuffer` is a `Sendable` wrapper around `CMSampleBuffer`. When the
// sendable version of `CMSampleBuffer` is available, it replaces this.

struct SampleBuffer: Sendable {

    nonisolated(unsafe) let cmSampleBuffer: CMSampleBuffer

    init(wrapping cmSampleBuffer: CMSampleBuffer) {
        self.cmSampleBuffer = cmSampleBuffer
    }

    var formatDescription: CMFormatDescription? { cmSampleBuffer.formatDescription }
    var presentationTimeStamp: CMTime { cmSampleBuffer.presentationTimeStamp }
    var imageBuffer: CVPixelBuffer? { cmSampleBuffer.imageBuffer }
    
    func propagateAttachments(to buffer: CMAttachmentBearerProtocol) {
        cmSampleBuffer.propagateAttachments(to: buffer)
    }
}

// `SampleBufferStream` is an asynchronous stream of video sample buffers.
typealias SampleBufferStream = AsyncIOStream<SampleBuffer, Error>

// `ProgressStream` is an asynchronous stream of progress (`0.0...1.0`) updates.
typealias ProgressStream = AsyncIOStream<Double, Error>

// `AsyncAssetReader` provides `AsyncIOStream` for the first video track it finds.
actor AsyncAssetReader: AsyncFrameProcessor {

    var inputStream: SampleBufferStream? // not used

    let inputURL: URL
    var videoSettings: [String: Any]

    // Create `AsyncAssetReader` for the specified video asset.
    init(inputURL: URL, videoSettings: [String: Any]? = nil) {
        self.inputURL = inputURL
        self.videoSettings = videoSettings ?? [:]
        avAsset = AVURLAsset(url: inputURL)
    }

    private let avAsset: AVURLAsset

    func configure(sourcePixelBufferAttributes: [String: Any]) throws {
        self.videoSettings = sourcePixelBufferAttributes
    }

    var outputStreams: [SampleBufferStream] = []
    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any] = [:]

    // Use this to get a stream of progress updates.
    func progressStream() async throws -> ProgressStream {
        progressStream = ProgressStream(bufferingPolicy: .bufferingNewest(1))
        return progressStream!
    }
    private var progressStream: ProgressStream?

    // Start reading the video frames and send them with `SampleBufferStream`.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard outputStreams.isEmpty == false else { throw Fault.missingSampleBufferStream }

        defer { finish() }

        let avAssetReader = try AVAssetReader(asset: avAsset)

        guard let videoTrack = try await avAsset.loadTracks(withMediaType: .video).first else {
            throw Fault.failedToFindVideoTrack
        }

        // This calculates the frame count to facilitate progress reporting.
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let duration = try await avAsset.load(.duration)
        let frameCount = duration.seconds * Double(frameRate)

        let trackOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                     outputSettings: videoSettings)
        guard avAssetReader.canAdd(trackOutput) else {
            throw Fault.cannotAddTrackOutput
        }

        avAssetReader.add(trackOutput)

        avAssetReader.startReading()

        // This iterates through all of the video track sample buffers.
        // It waits for the consumer to consume the previous `SampleBuffer`
        // before sending another.
        var frameNumber = 0.0
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {

            guard Task.isCancelled == false else { break }

            try await send(SampleBuffer(wrapping: sampleBuffer))

            frameNumber += 1.0
            try await progressStream?.send(frameNumber / frameCount)
        }
        progressStream?.finish()
        progressStream = nil
    }
}

extension AsyncAssetReader {

    func videoTrackDimensions() async throws -> CMVideoDimensions {

        guard let videoTrack = try await avAsset.loadTracks(withMediaType: .video).first else {
            throw Fault.failedToFindVideoTrack
        }
        guard let formatDescription = try await videoTrack.load(.formatDescriptions).first else {
            throw Fault.failedToFindFormatDescription
        }
        return formatDescription.dimensions
    }
}

extension AsyncAssetReader {
    enum Fault: Error {
        case overSubscribed
        case failedToFindVideoTrack
        case failedToFindFormatDescription
        case cannotAddTrackOutput
        case missingSampleBufferStream
    }

}

// `AsyncAssetWriter` writes a single video track from the provided
// `SampleBufferStream` input.
actor AsyncAssetWriter: AsyncFrameProcessor {

    let outputURL: URL

    // Create `AVAssetWriterInput` for the specified URL.
    init(outputURL: URL) {

        try? FileManager.default.removeItem(at: outputURL)

        self.outputURL = outputURL
    }

    // Use this to provide the `SampleBufferStream` input for the video track.
    func setInputStream(_ sampleBufferStream: SampleBufferStream) async throws {

        guard inputStream == nil else { throw Fault.overSubscribed }

        inputStream = sampleBufferStream
    }
    var inputStream: SampleBufferStream?
    var outputStreams: [SampleBufferStream] = []
    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any] = [:]

    // Start reading the video frames from the `SampleBufferStream` and write them
    // to disk using `AVAssetWriter`.
    // Be sure to call this from a dedicated `TaskGroup` task.
    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }

        let aVAssetWriter = try AVAssetWriter(url: outputURL, fileType: .mov)

        var assetWriterInput: AVAssetWriterInput? = nil

        var currentTimeStamp = CMTime.zero

        var startedWriting = false

        // This iterates through all of the video track sample buffers,
        // writing them to disk as soon as the system receives them.
        for try await sampleBuffer in inputStream {

            currentTimeStamp = sampleBuffer.presentationTimeStamp

            if assetWriterInput == nil {

                let newAssetWriterInput = AVAssetWriterInput(mediaType: .video,
                                                              outputSettings: [AVVideoCodecKey: AVVideoCodecType.hevc],
                                                              sourceFormatHint: sampleBuffer.formatDescription)

                guard aVAssetWriter.canAdd(newAssetWriterInput) else {
                    throw Fault.cannotAddInput
                }

                aVAssetWriter.add(newAssetWriterInput)

                assetWriterInput = newAssetWriterInput
                aVAssetWriter.startWriting()
                aVAssetWriter.startSession(atSourceTime: currentTimeStamp)
            }

            guard let assetWriterInput else { throw Fault.failedToCreateAVAssetWriterInput }

            try await assetWriterInput.waitUntilReadyForMoreMediaData()

            assetWriterInput.append(sampleBuffer.cmSampleBuffer)
            startedWriting = true
            try await send(sampleBuffer)
        }

        assetWriterInput?.markAsFinished()
        assetWriterInput = nil

        if startedWriting {
            aVAssetWriter.endSession(atSourceTime: currentTimeStamp)
            await aVAssetWriter.finishWriting()
        } else {
            aVAssetWriter.cancelWriting()
        }
    }
}

extension AsyncAssetWriter {
    enum Fault: Error {
        case overSubscribed
        case failedToCreateAVAssetWriter
        case failedToCreateAVAssetWriterInput
        case missingSampleBufferStream
        case missingFormatDescription
        case cannotAddInput
    }
}

// This provides a means to block the `AsyncAssetWriter` task while `AVAssetWriter` is busy.
// When the new Concurrency API is available, a new process will replace this.
extension AVAssetWriterInput {

    private static let assetWriterTimeout = 1.0

    func waitUntilReadyForMoreMediaData() async throws {

        let startTime = Date.now
        while isReadyForMoreMediaData == false {

            if Date.now.timeIntervalSince(startTime) > Self.assetWriterTimeout {
                throw Fault.assetWriterTimeout
            }

            try await Task.sleep(for: .milliseconds(10))
        }

    }
    enum Fault: Error {
        case assetWriterTimeout
    }
}
