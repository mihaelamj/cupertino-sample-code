/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The chroma key and transparent pixel-trimming class.
*/

import Accelerate
import Cocoa

/// - Tag: ImageProvider
class ImageProvider: ObservableObject {
    
    var cgImageFormatARGB = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.first.rawValue))!
    
    var cgImageFormatGray = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 1,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.none.rawValue))!
    
    @Published var originalImage = #imageLiteral(resourceName: "Tree_3_Palm_Tree.jpeg").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    @Published var alphaImage = emptyCGImage
    @Published var outputImage = emptyCGImage
    
    init() {
        // Create an `InterleavedFx4` pixel buffer from the original image.
        let sourceBuffer = try! vImage.PixelBuffer<vImage.InterleavedFx4>(
            cgImage: originalImage,
            cgImageFormat: &cgImageFormatARGB)
        
        // Create a `PlanarF` pixel buffer that represents the alpha channel.
        let alpha = Self.chromaKeyToAlpha(source: sourceBuffer,
                                          chromaKeyColor: .init(red: 91 / 255,
                                                                green: 155 / 255,
                                                                blue: 244 / 255,
                                                                alpha: 0),
                                          tolerance: 60)
        
        // Compute the bounding box for nontransparent pixels.
        let boundingBox = Self.boundingBoxForNonTransparentPixels(alphaBuffer: alpha)
        
        // Create an `InterleavedFx4` pixel buffer that's the cropped version
        // of the original image.
        let cropped = sourceBuffer.cropped(to: boundingBox)
        
        // Overwrite the alpha channel of the cropped image so that the chroma-key
        // background is transparent.
        cropped.overwriteChannels([0],
                                  withPlanarBuffer: alpha.cropped(to: boundingBox),
                                  destination: cropped)
        
        // Create a Core Graphics image of the final result.
        outputImage = cropped.makeCGImage(cgImageFormat: cgImageFormatARGB)!
        alphaImage = alpha.makeCGImage(cgImageFormat: cgImageFormatGray)!
    }
    
    static var emptyCGImage: CGImage = {
        let buffer = vImage.PixelBuffer(
            pixelValues: [0],
            size: .init(width: 1, height: 1),
            pixelFormat: vImage.Planar8.self)
        
        let fmt = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8 ,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent)
        
        return buffer.makeCGImage(cgImageFormat: fmt!)!
    }()
}
