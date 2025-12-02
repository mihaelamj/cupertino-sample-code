/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom compositor that outputs stereoscopic video frames.
*/

import AVFoundation
import os

class StereoOutputCompositor: NSObject, AVVideoCompositing {

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {

        // If no track identifier is found, cancel the request and return.
        guard let firstTrackIDNumber = request.sourceTrackIDs.first else {
            request.finishCancelledRequest()
            return
        }

        let firstTrackID = CMPersistentTrackID(truncating: firstTrackIDNumber)

        // Attempt to retrieve the tagged buffers in the source track.
        if let taggedBuffers = request.sourceTaggedDynamicBuffers(byTrackID: firstTrackID) {
            // Process the tagged buffers from stereoscopic source track.
            processTaggedBuffers(taggedBuffers: taggedBuffers, request: request)
        }
        // Attempt to retrieve the monoscopic video frame in the source track.
        else if let pixelBuffer = request.sourceFrame(byTrackID: firstTrackID) {
            // Process pixel buffer from monoscopic source track.
            processMonoscopicBuffer(sourcePixelBuffer: pixelBuffer, request: request)
        }
        // No source frames were found. Finish with an error.
        else {
            request.finish(with: CompositorError.invalidSource)
        }
    }

    /// Process tagged buffers from the stereoscopic source track.
    func processTaggedBuffers(taggedBuffers: [CMTaggedDynamicBuffer], request: AVAsynchronousVideoCompositionRequest) {
        let instruction = request.videoCompositionInstruction as? SpatialVideoCompositionInstruction
        let spatialVideoConfiguration = instruction?.spatialConfiguration
        let projectionTag = instruction?.projectionTag ?? .projectionType(.rectangular)

        var outputTaggedBuffers: [CMTaggedDynamicBuffer] = []

        // Go through tagged buffer for each eye.
        for taggedBuffer in taggedBuffers {
            guard case let .pixelBuffer(inputPixelBuffer) = taggedBuffer.content else {
                request.finish(with: CompositorError.invalidSource)
                return
            }

            guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
                request.finish(with: CompositorError.failedToCreateNewOutputPixelBuffer)
                return
            }

            PixelBufferHelper.filterPixelBufferWithColorInverter(inputPixelBuffer, to: outputPixelBuffer)

            // Attach the spatial video configuration to the output pixel buffer.
            if let spatialVideoConfiguration {
                do {
                    var mutableOutputPixelBuffer = CVMutablePixelBuffer(unsafeBuffer: outputPixelBuffer)
                    try request.attach(spatialVideoConfiguration, to: &mutableOutputPixelBuffer)
                } catch {
                    logger.error("Failed to associate pixel buffer with spatial video configuration: \(error)")
                    request.finish(with: error)
                    return
                }
            }

            // Output tagged buffer uses the same `stereoView` tag as the input tagged buffer.
            let stereoViewTag = taggedBuffer.tags.first { $0.rawCategory == CMTag.stereoView(.leftEye).rawCategory }
            if let stereoViewTag {
                let taggedBuffer = CMTaggedBuffer(tags: [stereoViewTag, projectionTag, .mediaType(.video)], pixelBuffer: outputPixelBuffer)
                outputTaggedBuffers.append(CMTaggedDynamicBuffer(unsafeBuffer: taggedBuffer))
            } else {
                logger.error("Unexpected: taggedBuffer does not have stereoView tag")
                request.finish(with: CompositorError.invalidSource)
                return
            }
        }
        request.finish(withComposedTaggedBuffers: outputTaggedBuffers)
    }

    /// Process pixel buffer from the monoscopic source track.
    func processMonoscopicBuffer(sourcePixelBuffer: CVPixelBuffer, request: AVAsynchronousVideoCompositionRequest) {

        let instruction = request.videoCompositionInstruction as? SpatialVideoCompositionInstruction
        let spatialVideoConfiguration = instruction?.spatialConfiguration
        let projectionTag = instruction?.projectionTag ?? .projectionType(.rectangular)

        var outputTaggedBuffers: [CMTaggedDynamicBuffer] = []

        guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
            request.finish(with: CompositorError.failedToCreateNewOutputPixelBuffer)
            return
        }

        // Render a new pixel buffer by inverting the colors of the original.
        PixelBufferHelper.filterPixelBufferWithColorInverter(CVReadOnlyPixelBuffer(unsafeBuffer: sourcePixelBuffer), to: outputPixelBuffer)

        // Attach the spatial configuration to the output pixel buffer.
        if let spatialVideoConfiguration {
            do {
                var mutableOutputPixelBuffer = CVMutablePixelBuffer(unsafeBuffer: outputPixelBuffer)
                try request.attach(spatialVideoConfiguration, to: &mutableOutputPixelBuffer)
            } catch {
                logger.error("Failed to associate pixel buffer with spatial video configuration: \(error)")
                request.finish(with: error)
                return
            }
        }

        // Output tagged buffers use the same output pixel buffer for left eye and right eye.
        outputTaggedBuffers.append(
            CMTaggedDynamicBuffer(
                unsafeBuffer: CMTaggedBuffer(tags: [.stereoView(.leftEye), projectionTag, .mediaType(.video)], pixelBuffer: outputPixelBuffer)
            )
        )
        outputTaggedBuffers.append(
            CMTaggedDynamicBuffer(
                unsafeBuffer: CMTaggedBuffer(tags: [.stereoView(.rightEye), projectionTag, .mediaType(.video)], pixelBuffer: outputPixelBuffer)
            )
        )

        request.finish(withComposedTaggedBuffers: outputTaggedBuffers)
    }

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // No implementation needed.
    }

    // A Boolean value that indicates whether the compositor handles source frames that contain high dynamic range (HDR) properties.
    let supportsHDRSourceFrames = true
    /// A Boolean value that indicates whether the custom compositor supports source tagged buffers.
    let supportsSourceTaggedBuffers = true

    /// The pixel buffer attributes that the compositor accepts for source frames.
    var sourcePixelBufferAttributes: [String: any Sendable]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
        ]
    ]

    /// The pixel buffer attributes that the compositor requires for pixel buffers that it creates.
    var requiredPixelBufferAttributesForRenderContext: [String: any Sendable] = [
        kCVPixelBufferPixelFormatTypeKey as String: [
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
        ]
    ]
}
