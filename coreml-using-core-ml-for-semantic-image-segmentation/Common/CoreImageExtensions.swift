/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The functions that extend Core Image for image processing.
*/

import CoreImage
import ImageIO
import UniformTypeIdentifiers

extension CIImage {
    /// Resizes the image to a size.
    func resized(to size: CGSize) -> CIImage {
        let outputScaleX = size.width / extent.width
        let outputScaleY = size.height / extent.height
        var outputImage = self.transformed(by: CGAffineTransform(scaleX: outputScaleX, y: outputScaleY))
        outputImage = outputImage.transformed(
            by: CGAffineTransform(translationX: -outputImage.extent.origin.x, y: -outputImage.extent.origin.y)
        )
        return outputImage
    }
}

extension CIContext {
    /// Renders an image to a new pixel buffer.
    func render(_ image: CIImage, pixelFormat: OSType) -> CVPixelBuffer? {
        var output: CVPixelBuffer!
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.extent.width),
            Int(image.extent.height),
            pixelFormat,
            nil,
            &output
        )
        guard status == kCVReturnSuccess else {
            return nil
        }
        render(image, to: output)
        return output
    }
}
