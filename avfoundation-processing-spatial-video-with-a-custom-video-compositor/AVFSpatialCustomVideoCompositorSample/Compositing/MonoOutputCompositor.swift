/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom compositor that outputs monoscopic video frames.
*/

import AVFoundation

class MonoOutputCompositor: NSObject, AVVideoCompositing {

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {

        // If no track identifier is found, cancel the request and return.
        guard let firstTrackIDNumber = request.sourceTrackIDs.first else {
            request.finishCancelledRequest()
            return
        }

        let firstTrackID = CMPersistentTrackID(truncating: firstTrackIDNumber)

        // Attempt to retrieve the tagged buffers in the source track.
        if let taggedBuffers = request.sourceTaggedDynamicBuffers(byTrackID: firstTrackID) {
            // Retrieve the pixel buffers for the left and right eyes from the stereoscopic source track.
            let (leftEyePixelBuffer, rightEyePixelBuffer) = PixelBufferHelper.findLeftAndRightEyePixelBuffers(in: taggedBuffers)

            // If the returned pixel buffers are nil, finish the request with an error.
            guard let leftEyePixelBuffer, let rightEyePixelBuffer else {
                request.finish(with: CompositorError.invalidSource)
                return
            }

            // Create a new output pixel buffer to render into.
            guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
                request.finish(with: CompositorError.failedToCreateNewOutputPixelBuffer)
                return
            }

            // Render the difference between the pixel buffers into a new composite pixel buffer.
            PixelBufferHelper.diffPixelBuffers(a: leftEyePixelBuffer, b: rightEyePixelBuffer, to: outputPixelBuffer)
            request.finish(withComposedVideoFrame: outputPixelBuffer)

        }
        // Attempt to retrieve the monoscopic video frame in the source track.
        else if let pixelBuffer = request.sourceFrame(byTrackID: firstTrackID) {
            // Create a new output pixel buffer to render into.
            guard let outputPixelBuffer = request.renderContext.newPixelBuffer() else {
                request.finish(with: CompositorError.failedToCreateNewOutputPixelBuffer)
                return
            }
            // Render a new pixel buffer by inverting the colors of the original.
            PixelBufferHelper.filterPixelBufferWithColorInverter(CVReadOnlyPixelBuffer(unsafeBuffer: pixelBuffer), to: outputPixelBuffer)
            request.finish(withComposedVideoFrame: outputPixelBuffer)
        }
        // No source frames were found. Finish with an error.
        else {
            request.finish(with: CompositorError.invalidSource)
        }
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
