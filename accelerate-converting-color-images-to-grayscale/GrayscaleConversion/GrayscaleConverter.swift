/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The color-to-grayscale converter class.
*/
import Cocoa
import Accelerate

class GrayscaleConverter: ObservableObject {
    
    /// The 8-bit grayscale output image.
    @Published var outputImage8Bit = GrayscaleConverter.emptyCGImage
    
    /// The 32-bit grayscale output image.
    @Published var outputImage32Bit = GrayscaleConverter.emptyCGImage
    
    /// The normalized red coefficient.
    ///
    /// The sum of the red, green, and blue normalized coefficients in `1.0`.
    @Published var normalizedRedCoefficient: Float = defaultRedCoefficient
    
    /// The red coefficient.
    @Published var redCoefficient = defaultRedCoefficient {
        didSet {
            Task {
                await convertToGrayscale()
            }
        }
    }
    
    /// The normalized green coefficient.
    ///
    /// The sum of the red, green, and blue normalized coefficients in `1.0`.
    @Published var normalizedGreenCoefficient: Float = defaultGreenCoefficient
    
    /// The green coefficient.
    @Published var greenCoefficient = defaultGreenCoefficient {
        didSet {
            Task {
                await convertToGrayscale()
            }
        }
    }
    
    /// The normalized blue coefficient.
    ///
    /// The sum of the red, green, and blue normalized coefficients in `1.0`.
    @Published var normalizedBlueCoefficient: Float = defaultBlueCoefficient
    
    /// The blue coefficient.
    @Published var blueCoefficient = defaultBlueCoefficient {
        didSet {
            Task {
                await convertToGrayscale()
            }
        }
    }
        
    /// The 8-bit-per-channel, 4-channel source pixel buffer.
    let sourceBuffer8 = try! vImage.PixelBuffer<vImage.Interleaved8x4>(
        cgImage: sourceImage,
        cgImageFormat: &GrayscaleConverter.sourceFormat8)
    
    /// The 32-bit-per-channel, 4-channel source pixel buffer.
    let sourceBufferF = try! vImage.PixelBuffer<vImage.InterleavedFx4>(
        cgImage: sourceImage,
        cgImageFormat: &GrayscaleConverter.sourceFormatF)
    
    /// The 8-bit planar destination pixel buffer.
    let destinationBuffer8 = vImage.PixelBuffer<vImage.Planar8>(width: sourceImage.width,
                                                                height: sourceImage.height)
    
    /// The 32-bit planar destination pixel buffer.
    let destinationBufferF = vImage.PixelBuffer<vImage.PlanarF>(width: sourceImage.width,
                                                                height: sourceImage.height)
    
    init() {
        Task {
            await convertToGrayscale()
        }
    }
    
    /// Returns the number of distinct colors in the 8-bit planar destination pixel buffer.
    var distinctColorCount8: Int {
        Set(destinationBuffer8.array).count
    }
    
    /// Returns the number of distinct colors in the 32-bit planar destination pixel buffer.
    var distinctColorCountF: Int {
        Set(destinationBufferF.array).count
    }
    
    /// Performs a matrix multiply of the color image and the normalized red, green, and blue coefficients
    /// to produce 8- and 32-bit grayscale representations of the RGB image.
    func convertToGrayscale() async {
        
        let scale = 1.0 / (redCoefficient + greenCoefficient + blueCoefficient)
        
        DispatchQueue.main.async { [self] in
            normalizedRedCoefficient = redCoefficient * scale
            normalizedGreenCoefficient = greenCoefficient * scale
            normalizedBlueCoefficient = blueCoefficient * scale
        }
        
        await withTaskGroup(of: Void.self) { group in
            
            group.addTask(priority: .userInitiated) { [self] in
                let divisor: Int = 0x1000
                let fDivisor = Float(divisor)
                
                sourceBuffer8.multiply(by: (0,
                                            Int(normalizedRedCoefficient * fDivisor),
                                            Int(normalizedGreenCoefficient * fDivisor),
                                            Int(normalizedBlueCoefficient * fDivisor)),
                                       divisor: divisor,
                                       preBias: (0, 0, 0, 0),
                                       postBias: 0,
                                       destination: destinationBuffer8)
                
                let result = destinationBuffer8.makeCGImage(
                    cgImageFormat: GrayscaleConverter.destinationFormat8)!
                
                DispatchQueue.main.async {
                    self.outputImage8Bit = result
                }
            }
            
            group.addTask(priority: .userInitiated) { [self] in
                sourceBufferF.multiply(by: (0,
                                            normalizedRedCoefficient,
                                            normalizedGreenCoefficient,
                                            normalizedBlueCoefficient),
                                       preBias: (0, 0, 0, 0),
                                       postBias: 0,
                                       destination: destinationBufferF)
                
                let result = destinationBufferF.makeCGImage(
                    cgImageFormat: GrayscaleConverter.destinationFormatF)!
                
                DispatchQueue.main.async {
                    self.outputImage32Bit = result
                }
            }
        }
    }
}

extension GrayscaleConverter {
    
    static let defaultRedCoefficient: Float = 0.2126
    static let defaultGreenCoefficient: Float = 0.7152
    static let defaultBlueCoefficient: Float = 0.0722
    
    static let sourceImage = #imageLiteral(resourceName: "Flowers_12_Assorted.jpeg").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    static var sourceFormat8 = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue))!
        
    static var sourceFormatF = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.noneSkipFirst.rawValue))!
    
    static var destinationFormat8 = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
    
    static var destinationFormatF = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.none.rawValue))!
    
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

