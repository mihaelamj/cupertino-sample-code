/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class for applying saturation and luma gamma changes to images.
*/

import Cocoa
import Accelerate
import Combine
class YpCbCrAdjustment: ObservableObject {
    
    var cancellableSaturation: AnyCancellable?
    var cancellableLumaGamma: AnyCancellable?
    
    @Published var saturation: Float = 1
    @Published var lumaGamma: Float = 1
    
    @Published var useLinear: Bool {
        didSet {
            argbSource = try! vImage.PixelBuffer<vImage.Interleaved8x4>(
                cgImage: sourceCGImage,
                cgImageFormat: &format)
            
            if useLinear {
                argbSource.remap(.sRGBToLinear)
            }
            
            ypCbCrPreTransformBuffers.convert(from: argbSource)
            applyAdjustment()
        }
    }
    
    @Published var outputImage: CGImage
    
    let width: Int
    let height: Int
    
    let image: NSImage
    let sourceCGImage: CGImage
    var format = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))!
    
    private lazy var argbSource: vImage.PixelBuffer<vImage.Interleaved8x4> = {
        return try! vImage.PixelBuffer<vImage.Interleaved8x4>(cgImage: sourceCGImage,
                                                              cgImageFormat: &format)
    }()
    
    private lazy var argbDestination: vImage.PixelBuffer<vImage.Interleaved8x4> = {
        return vImage.PixelBuffer<vImage.Interleaved8x4>(width: self.width,
                                                         height: self.height)
    }()
    
    lazy private var ypCbCrPreTransformBuffers: Yp8CbCr8PixelBuffers = {
        return Yp8CbCr8PixelBuffers(width: width, height: height)
    }()

    lazy private var ypCbCrPostTransformBuffers: Yp8CbCr8PixelBuffers = {
        return Yp8CbCr8PixelBuffers(width: width, height: height)
    }()
    
    private lazy var gammaDestination: vImage.PixelBuffer<vImage.PlanarF> = {
        return vImage.PixelBuffer<vImage.PlanarF>(width: ypCbCrPreTransformBuffers.cbcr.width,
                                                  height: ypCbCrPreTransformBuffers.cbcr.height)
    }()
    
    init(image: NSImage) {
        self.image = image
        
        guard
            let sourceCGImage = image.cgImage(forProposedRect: nil,
                                              context: nil,
                                              hints: nil)  else {
            fatalError("Unable to parse image.")
        }
        
        self.sourceCGImage = sourceCGImage
        
        outputImage = sourceCGImage
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        let useLinear = false
        
        self.useLinear = useLinear
        
        ypCbCrPreTransformBuffers.convert(from: argbSource)
        
        cancellableSaturation = $saturation
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { _ in
                self.applyAdjustment()
            }
        
        cancellableLumaGamma = $lumaGamma
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { _ in
                self.applyAdjustment()
            }
    }
    
    public func reset() {
        saturation = 1
        lumaGamma = 1
    }
    
    private func applyAdjustment() {
        if saturation > 1 {
            applyGammaToCbCr(gamma: 1 / saturation)
        } else {
            applyLinearToCbCr(saturation: saturation)
        }
        
        applyGammaToLuma(lumaGamma: lumaGamma)
        
        ypCbCrPostTransformBuffers.convert(to: argbDestination)
        
        if useLinear {
            argbDestination.remap(.linearToSRGB)
        }
        
        guard let result = argbDestination.makeCGImage(cgImageFormat: format) else {
            fatalError("Unable to create output image.")
        }
        
        DispatchQueue.main.async {
            self.outputImage = result
        }
    }
    
    private func applyGammaToLuma(lumaGamma: Float) {
        
        ypCbCrPreTransformBuffers.yp.applyGamma(
            linearParameters: (scale: 1, bias: 0),
            exponentialParameters: (scale: 1, preBias: 0, gamma: lumaGamma, postBias: 0),
            boundary: 0,
            destination: ypCbCrPostTransformBuffers.yp)
        
    }
    
    /// Reduces saturation.
    private func applyLinearToCbCr(saturation: Float) {
        let preBias = -128
        let divisor = 0x1000
        let postBias = 128 * divisor
        
        let factor = Int(saturation * Float(divisor))
        
        ypCbCrPreTransformBuffers.cbcr.multiply(by: factor,
                                                divisor: divisor,
                                                preBias: preBias,
                                                postBias: postBias,
                                                destination: ypCbCrPostTransformBuffers.cbcr)
        
    }
    
    /// Increases saturation.
    private func applyGammaToCbCr(gamma: Float) {
        
        // Convert 8-bit CbCr values to 32-bit.
        ypCbCrPreTransformBuffers.cbcr.convert(to: gammaDestination)
        
        // Scale 32-bit values from `0.0 ... 1.0` to `-1.0 ... 1.0`.
        gammaDestination.multiply(by: 2,
                                  preBias: 0, postBias: -1,
                                  destination: gammaDestination)
        
        // Apply gamma to 32-bit values.
        gammaDestination.applyGamma(.fullPrecision(gamma),
                                    destination: gammaDestination)
        
        // Scale 32-bit transformed values from `-1.0 ... 1.0` to `0 ... 1.0`.
        gammaDestination.multiply(by: 0.5,
                                  preBias: 1, postBias: 0,
                                  destination: gammaDestination)
        
        // Convert 32-bit transformed CbCr values to 8-bit.
        gammaDestination.convert(to: ypCbCrPostTransformBuffers.cbcr)
    }
}

// MARK: YpCbCr Structure

/// A structure that wraps discrete luminance and chrominance pixel buffers and provides methods to
/// convert to and from ARGB pixel buffers.
struct Yp8CbCr8PixelBuffers {
    /// The luminance pixel buffer.
    let yp: vImage.PixelBuffer<vImage.Planar8>
    
    /// The chrominance pixel buffer.
    let cbcr: vImage.PixelBuffer<vImage.Planar8>
    
    init(width: Int, height: Int) {
        yp = vImage.PixelBuffer<vImage.Planar8>(width: width,
                                                height: height)
        
        cbcr = vImage.PixelBuffer<vImage.Planar8>(width: width,
                                                  height: height / 2)
    }
    
    private let pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 0,
                                                     CbCr_bias: 128,
                                                     YpRangeMax: 255,
                                                     CbCrRangeMax: 255,
                                                     YpMax: 255,
                                                     YpMin: 0,
                                                     CbCrMax: 255,
                                                     CbCrMin: 0)
    
    private var argbToYpCbCr: vImage_ARGBToYpCbCr {
        var outInfo = vImage_ARGBToYpCbCr()
        
        withUnsafePointer(to: pixelRange) { ptr in
            _ = vImageConvert_ARGBToYpCbCr_GenerateConversion(
                kvImage_ARGBToYpCbCrMatrix_ITU_R_709_2,
                ptr,
                &outInfo,
                kvImageARGB8888,
                kvImage420Yp8_CbCr8,
                vImage_Flags(kvImageNoFlags))
        }
        return outInfo
    }
    
    func convert(from source: vImage.PixelBuffer<vImage.Interleaved8x4>) {
        source.withUnsafePointerToVImageBuffer { src in
            withUnsafePointer(to: argbToYpCbCr) { info in
                self.yp.withUnsafePointerToVImageBuffer { yp in
                    self.cbcr.withUnsafePointerToVImageBuffer { cbcr in
                        _ = vImageConvert_ARGB8888To420Yp8_CbCr8(
                            src,
                            yp,
                            cbcr,
                            info,
                            [3, 2, 1, 0],
                            vImage_Flags(kvImagePrintDiagnosticsToConsole))
                    }
                }
            }
        }
    }
    
    private var ypCbCrToARGB: vImage_YpCbCrToARGB {
        var outInfo = vImage_YpCbCrToARGB()
        
        withUnsafePointer(to: pixelRange) { ptr in
            _ = vImageConvert_YpCbCrToARGB_GenerateConversion(
                kvImage_YpCbCrToARGBMatrix_ITU_R_709_2,
                ptr,
                &outInfo,
                kvImage420Yp8_CbCr8,
                kvImageARGB8888,
                vImage_Flags(kvImageNoFlags))
        }
        
        return outInfo
    }
    
    func convert(to destination: vImage.PixelBuffer<vImage.Interleaved8x4>) {
        _ = withUnsafePointer(to: ypCbCrToARGB) { info in
            self.cbcr.withUnsafePointerToVImageBuffer { cbcrDest in
                self.yp.withUnsafePointerToVImageBuffer { ypDest in
                    destination.withUnsafePointerToVImageBuffer { argbDest in
                        vImageConvert_420Yp8_CbCr8ToARGB8888(
                            ypDest,
                            cbcrDest,
                            argbDest,
                            info,
                            [3, 2, 1, 0],
                            255,
                            vImage_Flags(kvImagePrintDiagnosticsToConsole))
                    }
                }
            }
        }
    }
}

// MARK: Pixel buffer extension

extension vImage.PixelBuffer where Format == vImage.Interleaved8x4 {
    
    enum Remap {
        case linearToSRGB
        case sRGBToLinear
        
        var gammaType: vImage.Gamma {
            switch self {
                case .linearToSRGB:
                    return .sRGBForwardHalfPrecision
                case .sRGBToLinear:
                    return .sRGBReverseHalfPrecision
            }
        }
    }
    
    func remap(_ remap: Remap) {
        self.applyGamma(remap.gammaType,
                        intermediateBuffer: nil,
                        destination: self)
    }
}

