/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates a video data output set to produce frames with a specific pixel format.
*/

import AVFoundation

extension AVCaptureVideoDataOutput {
    /// Creates a video data output with a pixel format.
    /// - Parameter pixelFormatType: The pixel format for the video output.
    static func withPixelFormatType(_ pixelFormatType: OSType) -> AVCaptureVideoDataOutput {
        let videoDataOutput = AVCaptureVideoDataOutput()
        let validPixelTypes = videoDataOutput.availableVideoPixelFormatTypes

        guard validPixelTypes.contains(pixelFormatType) else {
            var errorMessage = "`AVCaptureVideoDataOutput` doesn't support "
            errorMessage += "pixel format type: \(pixelFormatType)\n"
            errorMessage += "Please use one of these instead:\n"

            for (index, pixelType) in validPixelTypes.enumerated() {
                var subscriptString = " availableVideoPixelFormatTypes"
                subscriptString += "[\(index)]"
                subscriptString += String(format: " (0x%08x)\n", pixelType)

                errorMessage += subscriptString
            }

            fatalError(errorMessage)
        }

        // Configure the output pixel type.
        let pixelTypeKey = String(kCVPixelBufferPixelFormatTypeKey)
        videoDataOutput.videoSettings = [pixelTypeKey: pixelFormatType]

        return videoDataOutput
    }
}
