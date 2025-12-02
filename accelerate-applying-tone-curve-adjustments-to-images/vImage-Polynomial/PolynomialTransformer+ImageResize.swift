/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The polynomial transformer image resize extension.
*/

import Cocoa
import Accelerate

// `NSImage` Resize Function

extension PolynomialTransformer {
    
    /// Returns a new `NSImage` instance that's a scaled copy of the specified image.
    static func scaleImage(_ sourceImage: NSImage, ratio: CGFloat) -> NSImage? {
        
        var cgImageFormat = vImage_CGImageFormat(
            bitsPerComponent: 32,
            bitsPerPixel: 32 * 4,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(
                rawValue: CGBitmapInfo.byteOrder32Little.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGImageAlphaInfo.noneSkipFirst.rawValue))!
        
        let scaledSize = vImage.Size(width: Int(floor(sourceImage.size.width * ratio)),
                                     height: Int(floor(sourceImage.size.height * ratio)))
        
        guard
            let cgImage = sourceImage.cgImage(forProposedRect: nil,
                                              context: nil,
                                              hints: nil),
            let sourceBuffer = try? vImage.PixelBuffer(
                cgImage: cgImage, cgImageFormat: &cgImageFormat,
                pixelFormat: vImage.InterleavedFx4.self) else {
            return nil
        }
        
        let destinationBuffer = vImage.PixelBuffer(
            size: scaledSize,
            pixelFormat: vImage.InterleavedFx4.self)
        
        sourceBuffer.scale(destination: destinationBuffer)
        
        if let scaledImage = destinationBuffer.makeCGImage(cgImageFormat: cgImageFormat) {
            
            return NSImage(cgImage: scaledImage, size: .zero)
        } else {
            
            return nil
        }
    }
}
