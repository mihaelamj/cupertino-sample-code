/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
FFT halftone descreener class.
*/

import Accelerate
import Cocoa
import Combine

class HalftoneDescreener: ObservableObject {
    
    @Published var descreenedImage: CGImage
    
    @Published var threshold: Float = HalftoneDescreener.defaultThreshold {
        didSet {
            descreenedImage = HalftoneDescreener.descreen(
                imagePixels: imageSpatialDomainPixels,
                halftonePixels: halftoneSpatialDomainPixels,
                imageFrequencyDomainPixels: &imageFrequencyDomainPixels,
                halftoneFrequencyDomainPixels: &halftoneFrequencyDomainPixels,
                destinationSpatialDomainPixels: &destinationSpatialDomainPixels,
                halftoneSampleAmplitudes: &halftoneSampleAmplitudes,
                threshold: threshold)
        }
    }
    
    static let defaultThreshold = thresholds[2]
    static let thresholds: [Float] = [5e+05, 5e+06, 5e+07, 5e+08, 5e+09]
    
    static let imageWidth = 1024
    static let imageHeight = 1024
    static let pixelCount = imageWidth * imageHeight
    static let complexValuesCount = pixelCount / 2
    
    static let fftSetUp = vDSP.FFT2D(width: imageWidth,
                                     height: imageHeight,
                                     ofType: DSPSplitComplex.self)!
    
    let sourceImage: CGImage
    
    /// The `SplitComplex` structure that stores the source image spatial-domain pixels.
    let imageSpatialDomainPixels: SplitComplex
    
    /// The `SplitComplex` structure that stores the halftone sample spatial-domain pixels.
    let halftoneSpatialDomainPixels: SplitComplex
    
    /// The `SplitComplex` structure that stores the destination spatial-domain pixels.
    var destinationSpatialDomainPixels = SplitComplex(count: HalftoneDescreener.complexValuesCount)
    
    /// The `SplitComplex` structure that stores the source image frequency-domain pixels.
    var imageFrequencyDomainPixels = SplitComplex(count: HalftoneDescreener.complexValuesCount)
    
    /// The `SplitComplex` structure that stores the halftone sample frequency-domain pixels.
    var halftoneFrequencyDomainPixels = SplitComplex(count: HalftoneDescreener.complexValuesCount)
    
    /// The array that stores the square magnitudes of the halftone frequency-domain values.
    var halftoneSampleAmplitudes = [Float](repeating: 0,
                                           count: HalftoneDescreener.complexValuesCount)
    
    init(sourceImage: CGImage, halftoneImage: CGImage) {
        assert(sourceImage.width == HalftoneDescreener.imageWidth &&
               sourceImage.height == HalftoneDescreener.imageHeight &&
               halftoneImage.width == HalftoneDescreener.imageWidth &&
               halftoneImage.height == HalftoneDescreener.imageHeight,
               "Image must be \(HalftoneDescreener.imageWidth) x \(HalftoneDescreener.imageHeight)")
        
        self.sourceImage = sourceImage
        
        imageSpatialDomainPixels = SplitComplex(cgImage: sourceImage)
        halftoneSpatialDomainPixels = SplitComplex(cgImage: halftoneImage)
       
        descreenedImage = HalftoneDescreener.descreen(
            imagePixels: imageSpatialDomainPixels,
            halftonePixels: halftoneSpatialDomainPixels,
            imageFrequencyDomainPixels: &imageFrequencyDomainPixels,
            halftoneFrequencyDomainPixels: &halftoneFrequencyDomainPixels,
            destinationSpatialDomainPixels: &destinationSpatialDomainPixels,
            halftoneSampleAmplitudes: &halftoneSampleAmplitudes,
            threshold: HalftoneDescreener.defaultThreshold)
    }
    
    /// Reduce or remove the halftone artifacts from the supplied source pixels.
    ///
    /// - Parameter sourcePixels: A `SplitComplex` instance that contains the source halftone image.
    /// - Parameter halftonePixels: A `SplitComplex` instance that contains the halftone screen.
    /// - Parameter imageFrequencyDomainPixels: A `SplitComplex` instance where the function
    /// writes the frequency-domain representation of the source halftone image.
    /// - Parameter halftoneFrequencyDomainPixels: A `SplitComplex` instance where the function
    /// writes the frequency-domain representation of the halftone screen.
    /// - Parameter destinationSpatialDomainPixels: A `SplitComplex` instance where the function
    /// writes the descreened result.
    /// - Parameter halftoneSampleAmplitudes: An array of single-precision values where the
    /// function writes the square amplitudes of the frequency-domain halftone sample values.
    /// - Parameter threshold: The threshold at which the function zeroes the source image frequency-
    /// domain values.
    ///
    /// - Returns: A `CGImage` instance that represents the descreened result.
    static func descreen(imagePixels: SplitComplex,
                         halftonePixels: SplitComplex,
                         imageFrequencyDomainPixels: inout SplitComplex,
                         halftoneFrequencyDomainPixels: inout SplitComplex,
                         destinationSpatialDomainPixels: inout SplitComplex,
                         halftoneSampleAmplitudes: inout [Float],
                         threshold: Float) -> CGImage {
        
        fftSetUp.transform(input: imagePixels.dspSplitComplex,
                           output: &imageFrequencyDomainPixels.dspSplitComplex,
                           direction: .forward)
        
        fftSetUp.transform(input: halftonePixels.dspSplitComplex,
                           output: &halftoneFrequencyDomainPixels.dspSplitComplex,
                           direction: .forward)
        
        vDSP.squareMagnitudes(halftoneFrequencyDomainPixels.dspSplitComplex,
                              result: &halftoneSampleAmplitudes)
        
        /// Transform all values in `halftoneSampleAmplitude` that are greater than or equal to
        /// `threshold` to `-1`, and transform all items that are less than `threshold` to `1`.
        let outputConstant: Float = -1
        
        vDSP.threshold(halftoneSampleAmplitudes,
                       to: threshold,
                       with: .signedConstant(outputConstant),
                       result: &halftoneSampleAmplitudes)
        
        /// Transform all negative values in `halftoneSampleAmplitude` to `0`.
        vDSP.clip(halftoneSampleAmplitudes,
                  to: 0 ... 1,
                  result: &halftoneSampleAmplitudes)
        
        /// Multiply the source image frequency-domain pixels by `halftoneSampleAmplitude`.
        /// The multiplication result is a source frequency-domain pixel where the corresponding halftone
        /// frequency-domain pixels that are less than the threshold are set to one.
        vDSP.multiply(imageFrequencyDomainPixels.dspSplitComplex,
                      by: halftoneSampleAmplitudes,
                      result: &imageFrequencyDomainPixels.dspSplitComplex)
        
        fftSetUp.transform(input: imageFrequencyDomainPixels.dspSplitComplex,
                           output: &destinationSpatialDomainPixels.dspSplitComplex,
                           direction: .inverse)
        
        return destinationSpatialDomainPixels.cgImage
    }
}

/// A single-precision complex vector with the real and imaginary parts stored in separate arrays.
///
/// This class wraps a `DSPSplitComplex` instance and provides the storage for the real and imaginary
/// parts.
struct SplitComplex {

    /// The underlying storage for the real and imaginary parts of the complex numbers.
    let storage: SplitComplex.SplitComplexStorage
    
    var dspSplitComplex: DSPSplitComplex
    
    /// The count of complex numbers.
    let count: Int
    
    /// Creates a new `SplitComplex` instance that contains `count` complex numbers.
    init(count: Int) {
        storage = SplitComplex.SplitComplexStorage(count: count)
        
        dspSplitComplex = DSPSplitComplex(realp: storage.realPart.baseAddress!,
                                          imagp: storage.imaginaryPart.baseAddress!)
        
        self.count = count
    }
    
    /// Creates a new `SplitComplex` instance that contains the pixel values of the specified Core
    /// Graphics image.
    ///
    /// The initializer converts the image to grayscale with pixel values in the range `0...1` and
    /// copies the odd pixels to the real parts and even pixels to the imaginary parts of the array of
    /// complex numbers.
    init(cgImage: CGImage) {
        
        let pixelCount = cgImage.width * cgImage.height
        let complexValuesCount = pixelCount / 2
        
        self.init(count: complexValuesCount)
        
        let pixelsStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: pixelCount)
        defer {
            pixelsStorage.deallocate()
        }
        
        var tmpBuffer = vImage_Buffer(
            data: pixelsStorage.baseAddress,
            height: vImagePixelCount(cgImage.height),
            width: vImagePixelCount(cgImage.width),
            rowBytes: cgImage.width * MemoryLayout<Float>.stride)
        
        vImageBuffer_InitWithCGImage(
            &tmpBuffer,
            &Self.imageFormat,
            [0, 0, 0, 0],
            cgImage,
            vImage_Flags(kvImageNoAllocate))
        
        pixelsStorage.withMemoryRebound(to: DSPComplex.self) {
            
            vDSP_ctoz([DSPComplex]($0), 2,
                      &self.dspSplitComplex, 1,
                      vDSP_Length(complexValuesCount))
        }
    }
    
    /// Returns a grayscale Core Graphics image that represents the `SplitComplex` contents.
    var cgImage: CGImage {
        var floatPixels = [Float](fromSplitComplex: self.dspSplitComplex,
                                  scale: 1 / Float(count),
                                  count: count * 2)
        
        return floatPixels.withUnsafeMutableBytes {
            let tmpBuffer = vImage_Buffer(
                data: $0.baseAddress,
                height: vImagePixelCount(HalftoneDescreener.imageHeight),
                width: vImagePixelCount(HalftoneDescreener.imageWidth),
                rowBytes: HalftoneDescreener.imageWidth * MemoryLayout<Float>.stride)
            
            return try! tmpBuffer.createCGImage(format: SplitComplex.imageFormat)
        }
    }
    
    /// `SplitComplex` structures store their underlying memory in a reference type to allow
    /// automatic deallocation on `deinit`.
    class SplitComplexStorage {
        init(count: Int) {
            realPart = UnsafeMutableBufferPointer<Float>.allocate(capacity: count)
            imaginaryPart = UnsafeMutableBufferPointer<Float>.allocate(capacity: count)
        }
        
        /// The storage for the real parts of the complex numbers.
        let realPart: UnsafeMutableBufferPointer<Float>
        
        /// The storage for the imaginary parts of the complex numbers.
        let imaginaryPart: UnsafeMutableBufferPointer<Float>
        
        deinit {
            realPart.deallocate()
            imaginaryPart.deallocate()
        }
    }
    
    /// The image format that a `SplitComplex` instance uses to convert to and from
    /// Core Graphics images.
    fileprivate static var imageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue:
                                 kCGBitmapByteOrder32Host.rawValue |
                                 CGBitmapInfo.floatComponents.rawValue |
                                 CGImageAlphaInfo.none.rawValue))!
}
