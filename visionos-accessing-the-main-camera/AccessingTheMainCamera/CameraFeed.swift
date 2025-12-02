/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Renders the `pixelBuffer` in a `CameraFrame.Sample` to an `AVSampleBufferDisplayLayer`.
*/

@preconcurrency import AVFoundation
import ARKit

@MainActor
final class CameraFeed {
    /// A preview layer that presents the captured video frames.
    let preview = AVSampleBufferDisplayLayer()
    
    /// Renders the `pixelBuffer` in the `Sample` to the preview layer.
    /// - Parameters:
    ///     - using: The `sample` to render to the preview layer.
    func update(using sample: CameraFrame.Sample?) async throws {
        guard let sample else {
            await preview.sampleBufferRenderer.flush(removingDisplayedImage: true)
            return
        }
        
        let presentationTimeStamp = CMTime(seconds: sample.parameters.captureTimestamp, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let timingInfo = CMSampleTimingInfo(duration: .invalid,
                                            presentationTimeStamp: presentationTimeStamp,
                                            decodeTimeStamp: .invalid)

        try? sample.buffer.withUnsafeBuffer { pixelBuffer in
            let sampleBuffer = try CMSampleBuffer(imageBuffer: pixelBuffer,
                                                  formatDescription: CMVideoFormatDescription(imageBuffer: pixelBuffer),
                                                  sampleTiming: timingInfo)
            if preview.sampleBufferRenderer.isReadyForMoreMediaData {
                preview.sampleBufferRenderer.enqueue(sampleBuffer)
            }
        }
    }
}
