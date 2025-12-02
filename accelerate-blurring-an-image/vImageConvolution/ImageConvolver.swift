/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The ImageConvolver class that implements blur techniques.
*/

import Cocoa
import Accelerate

class ImageConvolver: ObservableObject {
    
    enum Mode: String, CaseIterable {
        case none = "None"
        case box = "Box"
        case tent = "Tent"
        case general = "General"
        case separable = "Separable"
        case multi = "Multiple Kernel"
    }
    
    @Published var mode: ImageConvolver.Mode = .none {
        didSet {
            switch mode {
                case .none:
                    none()
                case .box:
                    box()
                case .tent:
                    tent()
                case .general:
                    generalConvolution()
                case .separable:
                    separableConvoution()
                case .multi:
                    multiKernelConvolution()
            }
            outputImage = destinationBuffer.makeCGImage(cgImageFormat: cgImageFormat)!
        }
    }
    
    @Published var outputImage: CGImage
    
    let kernelLength = 51
    let sourceBuffer: vImage.PixelBuffer<vImage.Interleaved8x4>
    let destinationBuffer: vImage.PixelBuffer<vImage.Interleaved8x4>
    
    var cgImageFormat = vImage_CGImageFormat(bitsPerComponent: 8,
                                           bitsPerPixel: 8 * 4,
                                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))!
    
    init(sourceImage: NSImage) {
        
        guard let cgImage = sourceImage.cgImage(forProposedRect: nil,
                                                context: nil,
                                                hints: nil),
        let buffer = try? vImage.PixelBuffer<vImage.Interleaved8x4>(cgImage: cgImage,
                                                                 cgImageFormat: &cgImageFormat) else {
            fatalError("Unable to create `CGImage`.")
        }
        
        sourceBuffer = buffer
        
        outputImage = sourceBuffer.makeCGImage(cgImageFormat: cgImageFormat)!
        destinationBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(size: sourceBuffer.size)
        
        generalConvolution()
    }
}

// Convolution functions.
extension ImageConvolver {
    
    func none() {
        sourceBuffer.copy(to: destinationBuffer)
    }
    
    func box() {
        sourceBuffer.boxConvolve(kernelSize: .init(width: kernelLength,
                                                   height: kernelLength),
                                 edgeMode: .extend,
                                 destination: destinationBuffer)
    }
    
    func tent() {
        sourceBuffer.tentConvolve(kernelSize: .init(width: kernelLength,
                                                    height: kernelLength),
                                  edgeMode: .extend,
                                  destination: destinationBuffer)
    }
    
    func generalConvolution() {
        
        let window = vDSP.window(ofType: Float.self,
                                 usingSequence: .hanningDenormalized,
                                 count: kernelLength,
                                 isHalfWindow: false)

        let matrix = [Float](unsafeUninitializedCapacity: kernelLength * kernelLength) {
            buffer, initializedCount in
            
            cblas_sgemm(CblasColMajor,
                        CblasNoTrans, CblasNoTrans,
                        __LAPACK_int(kernelLength),
                        __LAPACK_int(kernelLength),
                        1,
                        1,
                        window, __LAPACK_int(kernelLength),
                        window, 1,
                        0,
                        buffer.baseAddress!, __LAPACK_int(kernelLength))
            
            initializedCount = kernelLength * kernelLength
        }
        
        let weights = vDSP.floatingPointToInteger(matrix,
                                                  integerType: Int16.self,
                                                  rounding: .towardNearestInteger)
        
        let kernel = vImage.ConvolutionKernel2D(values: weights,
                                                size: .init(width: kernelLength,
                                                            height: kernelLength))
        
        let divisor = weights.map { Int32($0) }.reduce(0, +)
        
        sourceBuffer.convolve(with: kernel,
                              divisor: divisor,
                              edgeMode: .extend,
                              destination: destinationBuffer)

    }
    
    func separableConvoution() {
        
        var kernel = vDSP.window(ofType: Float.self,
                                 usingSequence: .hanningDenormalized,
                                 count: kernelLength,
                                 isHalfWindow: false)
        let scale = 1.0 / vDSP.sum(kernel)
        vDSP.multiply(scale, kernel,
                      result: &kernel)
       
        let planarSourceBuffers = vImage.PixelBuffer<vImage.Planar8x4>(size: sourceBuffer.size)
        let planarDestinationBuffers = vImage.PixelBuffer<vImage.Planar8x4>(size: sourceBuffer.size)
        
        sourceBuffer.deinterleave(destination: planarSourceBuffers)
        
        planarSourceBuffers.separableConvolve(horizontalKernel: kernel,
                                              verticalKernel: kernel,
                                              edgeMode: .extend,
                                              destination: planarDestinationBuffers)
        
        planarDestinationBuffers.interleave(destination: destinationBuffer)
    }
    
    func multiKernelConvolution() {
        
        let radius = kernelLength / 2
        let diameter = (radius * 2) + 1
        
        let kernels: [vImage.ConvolutionKernel2D<Int16>] = (1 ... 4).map { index in
            let weights = [Int16](unsafeUninitializedCapacity: diameter * diameter) {
                buffer, initializedCount in
                for x in 0 ..< diameter {
                    for y in 0 ..< diameter {
                        if hypot(Float(radius - x), Float(radius - y)) < Float(radius / index) {
                            buffer[y * diameter + x] = 1
                        } else {
                            buffer[y * diameter + x] = 0
                        }
                    }
                }
                
                initializedCount = diameter * diameter
            }
            
            return vImage.ConvolutionKernel2D(values: weights,
                                              size: .init(width: kernelLength,
                                                          height: kernelLength))
        }
        
        let divisors = kernels.map { return Int32($0.values.reduce(0, +)) }

        sourceBuffer.convolve(with: (kernels[0], kernels[1], kernels[2], kernels[3]),
                              divisors: (divisors[0], divisors[1], divisors[2], divisors[3]),
                              edgeMode: .extend,
                              destination: destinationBuffer)
    }
}

/* The following kernel, which is based on a Hann window, is suitable for use with an integer format. This isn't in the sample app. */

let kernel2D: [Int16] = [
    0,    0,    0,      0,      0,      0,      0,
    0,    2025, 6120,   8145,   6120,   2025,   0,
    0,    6120, 18496,  24616,  18496,  6120,   0,
    0,    8145, 24616,  32761,  24616,  8145,   0,
    0,    6120, 18496,  24616,  18496,  6120,   0,
    0,    2025, 6120,   8145,   6120,   2025,   0,
    0,    0,    0,      0,      0,      0,      0
]

let kernel1D: [Float] = [0, 45, 136, 181, 136, 45, 0]
