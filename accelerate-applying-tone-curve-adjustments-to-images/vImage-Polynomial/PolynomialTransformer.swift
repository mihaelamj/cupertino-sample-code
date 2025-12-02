/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The polynomial transformer class.
*/

import Accelerate
import Cocoa
import Combine

class PolynomialTransformer: ObservableObject {
    
    /// The number of control points on each color curve.
    static let count = 5
    
    var sourceImage = #imageLiteral(resourceName: "Orchid.tif") {
        didSet {
            setup()
        }
    }
    
    /// This app converts supplied images to RGB, 32-bit per channel.
    static var sourceImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.noneSkipLast.rawValue))!
    
    /// The interleaved source and destination image buffers that the sample uses for
    /// converting to and from `CGImage` instances.
    var srcInterleavedBuffer: vImage.PixelBuffer<vImage.InterleavedFx4>!
    var destInterleavedBuffer: vImage.PixelBuffer<vImage.InterleavedFx4>!
    
    /// The planar source and destination image buffers that the sample uses for
    /// applying per-channel polynomial color transforms.
    var srcPlanarBuffers: vImage.PixelBuffer<vImage.PlanarFx4>!
    var destPlanarBuffers: vImage.PixelBuffer<vImage.PlanarFx4>!
    
    @Published var outputImage: CGImage!
    
    /// The coefficients for the red channel that `calculateCoefficients` returns for the
    /// handle values in `redHandleValues`.
    @Published var redCoefficients = [Float](
        repeating: 0,
        count: PolynomialTransformer.count)
    
    /// The handle values for the red channel.
    @Published var redHandleValues: [Double]! {
        didSet {
            redCoefficients = calculateAndApplyPolynomial(
                forHandleValues: redHandleValues,
                at: 0,
                source: srcPlanarBuffers,
                destination: destPlanarBuffers)
            
            displayPlanarDestinationBuffers()
        }
    }
    
    /// The coefficients for the green channel that `calculateCoefficients` returns for the
    /// handle values in `greenHandleValues`.
    @Published var greenCoefficients = [Float](
        repeating: 0,
        count: PolynomialTransformer.count)
    
    /// The handle values for the green channel.
    @Published var greenHandleValues: [Double]! {
        didSet {
            greenCoefficients = calculateAndApplyPolynomial(
                forHandleValues: greenHandleValues,
                at: 1,
                source: srcPlanarBuffers,
                destination: destPlanarBuffers)
            
            displayPlanarDestinationBuffers()
        }
    }
    
    /// The coefficients for the blue channel that `calculateCoefficients` returns for the
    /// handle values in `greenHandleValues`.
    @Published var blueCoefficients = [Float](
        repeating: 0,
        count: PolynomialTransformer.count)
    
    /// The handle values for the blue channel.
    @Published var blueHandleValues: [Double]! {
        didSet {
            blueCoefficients = calculateAndApplyPolynomial(
                forHandleValues: blueHandleValues,
                at: 2,
                source: srcPlanarBuffers,
                destination: destPlanarBuffers)
            
            displayPlanarDestinationBuffers()
        }
    }
    
    /// The Vandermonde matrix that the `calculateCoefficients` function uses to
    /// calculate the polynomial coefficients for a set of handle values.
    let vandermonde: [Float] = {
        let matrix: [[Float]] = vDSP.ramp(
            in: Float() ... 1,
            count: PolynomialTransformer.count).map { base in
                
                let bases = [Float](
                    repeating: base,
                    count: PolynomialTransformer.count)
                let exponents = vDSP.ramp(
                    in: Float() ... 4,
                    count: PolynomialTransformer.count)
                
                return vForce.pow(
                    bases: bases,
                    exponents: exponents)
        }
        return matrix.flatMap { $0 }
    }()
    
    init() {
        setup()
    }
    
    /// The `setup` function populates the `srcInterleavedBuffer` and `srcPlanarBuffers`
    /// with the image data from `sourceImage`, and initializes the `destInterleavedBuffer`
    /// and `destPlanarBuffers` to the image size.
    ///
    /// If the source image has a dimension greater than 1024 pixels, the function scales it  to fit within a
    /// 1024 x 1024 bounding box. This improves performance in the app. In a production app, save or export
    /// a final image that matches the original image's dimensions.
    func setup() {

        let maxDimension: CGFloat = 1024
        if max(sourceImage.size.width, sourceImage.size.height) > maxDimension {
            let ratio = maxDimension / max(sourceImage.size.width, sourceImage.size.height)
            
            if let proxyImage = PolynomialTransformer.scaleImage(
                sourceImage,
                ratio: ratio) {
                sourceImage = proxyImage
            } else {
                NSLog("`PolynomialTransformer.scaleImage` failed, using original image.")
            }
        }
        
        guard
            let sourceCGImage = sourceImage.cgImage(
                forProposedRect: nil, context: nil, hints: nil),
            let sourceBuffer = try? vImage.PixelBuffer(
                cgImage: sourceCGImage,
                cgImageFormat: &PolynomialTransformer.sourceImageFormat,
                pixelFormat: vImage.InterleavedFx4.self) else {
            fatalError("Error initializing `PolynomialTransformer` instance.")
        }
        
        outputImage = sourceCGImage
        
        /// Initialize the interleaved image buffers.
        srcInterleavedBuffer = sourceBuffer
        destInterleavedBuffer = vImage.PixelBuffer(
            size: srcInterleavedBuffer.size,
            pixelFormat: vImage.InterleavedFx4.self)
        
        /// Initialize the planar image buffers.
        srcPlanarBuffers = vImage.PixelBuffer(
            size: srcInterleavedBuffer.size,
            pixelFormat: vImage.PlanarFx4.self)
        destPlanarBuffers = vImage.PixelBuffer(
            size: srcInterleavedBuffer.size,
            pixelFormat: vImage.PlanarFx4.self)
        
        /// Create default values for each color channel that represent a linear response curve.
        redHandleValues = vDSP.ramp(
            in: 0 ... 1,
            count: PolynomialTransformer.count)
        
        greenHandleValues = vDSP.ramp(
            in: 0 ... 1,
            count: PolynomialTransformer.count)
        
        blueHandleValues = vDSP.ramp(
            in: 0 ... 1,
            count: PolynomialTransformer.count)
        
        populatePlanarSourceBuffers()
        applyPolynomialsToAllChannels()
    }
    
    /// Populates the planar buffers from the interleaved source image buffer.
    func populatePlanarSourceBuffers() {
        
        srcInterleavedBuffer.deinterleave(destination: srcPlanarBuffers)
    }
    
    /// Applies the polynomials to each of the red, green, and blue planar image buffers.
    func applyPolynomialsToAllChannels() {
        redCoefficients = calculateAndApplyPolynomial(
            forHandleValues: redHandleValues,
            at: 0,
            source: srcPlanarBuffers,
            destination: destPlanarBuffers)
        
        greenCoefficients = calculateAndApplyPolynomial(
            forHandleValues: greenHandleValues,
            at: 1,
            source: srcPlanarBuffers,
            destination: destPlanarBuffers)
        
        blueCoefficients = calculateAndApplyPolynomial(
            forHandleValues: blueHandleValues,
            at: 2,
            source: srcPlanarBuffers,
            destination: destPlanarBuffers)
        
        displayPlanarDestinationBuffers()
    }
    
    /// Calculates and returns the coefficients for the specified handle values, and applies the
    /// polynomial to the planar buffer at the specified index.
    func calculateAndApplyPolynomial(
        forHandleValues values: [Double],
        at planeIndex: Int,
        source: vImage.PixelBuffer<vImage.PlanarFx4>,
        destination: vImage.PixelBuffer<vImage.PlanarFx4>) -> [Float] {
            
            let coefficients = calculateCoefficients(values: values.map { Float($0) })
            
            source.withUnsafePixelBuffer(at: planeIndex) { src in
                destination.withUnsafePixelBuffer(at: planeIndex) { dest in
                    
                    src.applyPolynomial(
                        coefficientSegments: [coefficients],
                        boundaries: [-.infinity, .infinity],
                        destination: dest)
                }
            }
            
            return coefficients
        }
    
    /// Sets the output image to an RGB representation of the transformed planar buffers.
    func displayPlanarDestinationBuffers() {
        
        destPlanarBuffers.interleave(destination: destInterleavedBuffer)
        
        guard let result = destInterleavedBuffer.makeCGImage(
            cgImageFormat: PolynomialTransformer.sourceImageFormat) else {
            NSLog("Can't create output `CGImage`.")
            return
        }
        
        outputImage = result
    }
    
    /// Returns the coefficients for an interpolating polynomial using the Vandermonde Method from the
    /// specified values.
    ///
    /// The coefficients are the _x_ in _Ax = b_ where _A_ is a Vandermonde matrix and the elements
    /// of `b` are the five value sliders in the user interface.
    func calculateCoefficients(values: [Float]) -> [Float] {
        var a = vandermonde
        var b = values
        
        do {
            try PolynomialTransformer.solveLinearSystem(matrixA: &a,
                                                        matrixB: &b,
                                                        count: b.count)
            
        } catch {
            fatalError("Unable to solve linear system.")
        }
        
        return b
    }
}
