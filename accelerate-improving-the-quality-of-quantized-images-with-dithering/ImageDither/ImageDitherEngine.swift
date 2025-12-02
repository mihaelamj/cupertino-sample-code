/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image-dithering class.
*/

import Accelerate
import Cocoa

class ImageDitherEngine: ObservableObject {

    enum DitheringType: String, CaseIterable {
        case none = "None"
        case orderedGaussian = "Ordered Gaussian"
        case orderedUniform = "Ordered Uniform"
        case floydSteinberg = "Floyd Steinberg"
        case atkinson = "Atkinson"
        
        var dither: Int32 {
            switch self {
                case .none:
                    return Int32(kvImageConvert_DitherNone)
                case .orderedGaussian:
                    return Int32(kvImageConvert_DitherOrdered | kvImageConvert_OrderedGaussianBlue)
                case .orderedUniform:
                    return Int32(kvImageConvert_DitherOrdered | kvImageConvert_OrderedUniformBlue)
                case .floydSteinberg:
                    return Int32(kvImageConvert_DitherFloydSteinberg)
                case .atkinson:
                    return Int32(kvImageConvert_DitherAtkinson)
            }
        }
    }
    
    @Published var ditheringType = DitheringType.none {
        didSet {
            applyImageDither()
        }
    }
    
    @Published var outputImage = ImageDitherEngine.emptyCGImage
    
    let sourceImage = #imageLiteral(resourceName: "Flowers_17_Purple_Status.jpeg").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    let sourceFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: .init(rawValue: CGImageAlphaInfo.none.rawValue))!
    
    let destinationFormat = vImage_CGImageFormat(
        bitsPerComponent: 1,
        bitsPerPixel: 1,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: .init(rawValue: CGImageAlphaInfo.none.rawValue))!
    
    let sourceBuffer: vImage_Buffer
    let destinationBuffer: vImage_Buffer
    
    init() {
        
        do {
            sourceBuffer = try vImage_Buffer(
                cgImage: sourceImage,
                format: sourceFormat)
            
            destinationBuffer = try vImage_Buffer(
                size: sourceBuffer.size,
                bitsPerPixel: destinationFormat.bitsPerPixel)
        } catch {
            fatalError("Unable to create vImage buffers.")
        }
        
        applyImageDither()
    }
    
    deinit {
        sourceBuffer.free()
        destinationBuffer.free()
    }
    
    func applyImageDither() {
        
        withUnsafePointer(to: sourceBuffer) { src in
            withUnsafePointer(to: destinationBuffer) { dest in
                _ = vImageConvert_Planar8toPlanar1(
                    src, dest,
                    nil,
                    ditheringType.dither,
                    vImage_Flags(kvImageNoFlags))
            }
        }
        
        outputImage = try! destinationBuffer.createCGImage(format: destinationFormat)
    }
}

extension ImageDitherEngine {
    /// A 1x1 Core Graphics image.
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
