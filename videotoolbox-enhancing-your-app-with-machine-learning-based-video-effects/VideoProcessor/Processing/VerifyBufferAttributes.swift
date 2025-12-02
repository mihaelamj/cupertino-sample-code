/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `VerifyBufferAttributes`, which is an asynchronous process that
   ensures the buffer attributes meet the needs of the following processor.
*/

import Foundation
@preconcurrency import VideoToolbox
import os

actor VerifyBufferAttributes: AsyncFrameProcessor {

    init(pixelBufferAttributes: [String: Any]) throws {

        sourcePixelBufferAttributes = pixelBufferAttributes
        pixelBufferPool = try Self.createPixelBufferPool(for: pixelBufferAttributes)
    }

    // Input and output streams from `AVAssetReader` and for `AVAssetWriter`.
    var inputStream: SampleBufferStream?
    var outputStreams: [SampleBufferStream] = []

    nonisolated(unsafe) var sourcePixelBufferAttributes: [String: Any]

    let pixelBufferPool: CVPixelBufferPool

    nonisolated(unsafe) let frameProcessor = VTFrameProcessor()

    // This iterates across all of the input pixel buffers and verifies
    // they're compatible with the `sourcePixelBufferAttributes`.
    // If they aren't compatible, it creates a compatible `pixelBuffer` and copies
    // the image from the incompatible buffer using `VTPixelTransferSession`

    func run() async throws {

        guard let inputStream else { throw Fault.missingSampleBufferStream }
        guard !outputStreams.isEmpty else { throw Fault.missingSampleBufferStream }

        var transferSession: VTPixelTransferSession?
        guard (VTPixelTransferSessionCreate(allocator: kCFAllocatorDefault,
                                            pixelTransferSessionOut: &transferSession) == noErr),
              let transferSession else {
            throw Fault.failedToCreateTransferSession
        }

        defer {
            VTPixelTransferSessionInvalidate(transferSession)
            finish()
        }

        for try await inputSampleBuffer in inputStream {

            if try isSampleBufferCompatible(inputSampleBuffer) {

                try await send(inputSampleBuffer)

            } else {

                let newSampleBuffer = try createNewBuffer(from: inputSampleBuffer,
                                                          using: transferSession)

                try await send(newSampleBuffer)
            }
        }
    }

    // Verify that the buffer meets the requirements.
    private nonisolated func isSampleBufferCompatible(_ sampleBuffer: SampleBuffer) throws -> Bool {

        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            throw Fault.missingImageBuffer
        }

        guard let receivedPixelBufferAttributes = CVPixelBufferCopyCreationAttributes(pixelBuffer) as? [String: Any] else {
            throw Fault.failedToCopyAttributes
        }

        let criticalKeys = [
            kCVPixelBufferExtendedPixelsLeftKey as String,
            kCVPixelBufferExtendedPixelsTopKey as String,
            kCVPixelBufferExtendedPixelsRightKey as String,
            kCVPixelBufferExtendedPixelsBottomKey as String
        ]

        var isCompatible = true

        for criticalKey in criticalKeys {

            if let desiredValue = sourcePixelBufferAttributes[criticalKey] as? Int {
                let receivedValue = (receivedPixelBufferAttributes[criticalKey] as? Int) ?? 0

                if receivedValue != desiredValue {
                    isCompatible = false
                    break
                }
            }
        }
        return isCompatible
    }

    // Create a buffer that meets the requirements.
    private func createNewBuffer(from sampleBuffer: SampleBuffer,
                                 using transferSession: VTPixelTransferSession) throws -> SampleBuffer {
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            throw Fault.missingImageBuffer
        }

        let newPixelBuffer = try Self.createPixelBuffer(from: pixelBufferPool)

        guard VTPixelTransferSessionTransferImage(transferSession,
                                                  from: pixelBuffer,
                                                  to: newPixelBuffer) == noErr else {
            throw Fault.failedToPerformPixelTransfer
        }
        return try Self.createSampleBuffer(from: newPixelBuffer,
                                           sampleBuffer.presentationTimeStamp)
    }
}
