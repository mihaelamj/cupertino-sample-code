/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that provides custom resampling for shear operations.
*/

import Accelerate
import Cocoa

class CustomResamplingEngine: ObservableObject {
    
    enum Mode: String, CaseIterable, Identifiable {
        case originalImage = "Original Image"
        case lanczos = "Lanczos 5x5"
        case custom = "Custom"
        
        var id: Self { self }
    }
    
    @Published var mode = Mode.custom {
        didSet {
            switch mode {
                case .originalImage:
                    outputImage = image
                case .custom:
                    outputImage = getShearedImage(useCustomResampling: true)
                case .lanczos:
                    outputImage = getShearedImage(useCustomResampling: false)
            }
        }
    }

    @Published var outputImage = CustomResamplingEngine.emptyCGImage
    
    let image = #imageLiteral(resourceName: "sample_drawing2.png").cgImage(forProposedRect: nil, context: nil, hints: nil)!
    
    var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                      bitsPerPixel: 8,
                                      colorSpace: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
    
    let sourceBuffer: vImage.PixelBuffer<vImage.Planar8>
    
    let intermediateBuffer: vImage.PixelBuffer<vImage.Planar8>
    
    let destinationBuffer: vImage.PixelBuffer<vImage.Planar8>
    
    init() {
        sourceBuffer = try! vImage.PixelBuffer(cgImage: image,
                                               cgImageFormat: &format)
        
        intermediateBuffer = vImage.PixelBuffer(size: sourceBuffer.size)
        destinationBuffer = vImage.PixelBuffer(size: sourceBuffer.size)
        
        outputImage = getShearedImage(useCustomResampling: true)
    }
    
    func getShearedImage(useCustomResampling: Bool) -> CGImage {
        
        let resamplingFilter: ResamplingFilter
        
        let scale: Float = 30
        
        if useCustomResampling {
            // A linear interpolation resampling function.
            // `inPointer` contains a series of pixel distances
            // from the current pixel. The function writes a set
            // of kernel weights to `outPointer`.
            func kernelFunc(inPointer: UnsafePointer<Float>?,
                            outPointer: UnsafeMutablePointer<Float>?,
                            count: UInt,
                            userData: UnsafeMutableRawPointer?) {
                if let inPointer = inPointer, let outPointer = outPointer {
                    let absolutePixelPositions =
                    Array(UnsafeBufferPointer(start: inPointer,
                                              count: Int(count))).map {
                        abs($0)
                    }
                    
                    let kernelValues = absolutePixelPositions.map {
                        (absolutePixelPositions.max()! - $0)
                    }
                    
                    let divisor = vDSP.sum(kernelValues)
                    let normalizedKernelValues = vDSP.multiply(1 / divisor, kernelValues)
                    
                    outPointer.update(from: normalizedKernelValues,
                                      count: Int(count))
                }
            }
            
            // Given a specified kernel width, calculate and allocate
            // the memory that the resampling filter requires.
            let kernelWidth: Float = 1.5
            
            let size = vImageGetResamplingFilterSize(scale,
                                                     kernelFunc,
                                                     kernelWidth,
                                                     vImage_Flags(kvImageNoFlags))
            
            resamplingFilter = ResamplingFilter.allocate(byteCount: size,
                                                         alignment: 1)
            
            // Populate `resamplingFilter` with the custom linear
            // resampling filter.
            vImageNewResamplingFilterForFunctionUsingBuffer(resamplingFilter,
                                                            scale,
                                                            kernelFunc,
                                                            kernelWidth,
                                                            nil,
                                                            vImage_Flags(kvImageNoFlags))
        } else {
            // Create a high-quality Lanczos resampling filter.
            resamplingFilter = vImageNewResamplingFilter(scale,
                                                         vImage_Flags(kvImageHighQualityResampling))
            
        }
        // Perform a 2D scale about the center of the buffer in two separate passes.
        let height = Float(sourceBuffer.height)
        let yTranslate = (height - height * scale) * 0.5
        
        sourceBuffer.shear(direction: .vertical,
                           translate: yTranslate,
                           slope: 0,
                           resamplingFilter: resamplingFilter,
                           destination: intermediateBuffer)
        
        let width = Float(sourceBuffer.width)
        let xTranslate = (width - width * scale) * 0.5
        
        intermediateBuffer.shear(direction: .horizontal,
                                 translate: xTranslate,
                                 slope: 0,
                                 resamplingFilter: resamplingFilter,
                                 destination: destinationBuffer)
        
        // Release the resampling filter using the correct approach for the type.
        if useCustomResampling {
            resamplingFilter.deallocate()
        } else {
            vImageDestroyResamplingFilter(resamplingFilter)
        }
        
        return destinationBuffer.makeCGImage(cgImageFormat: format) ?? Self.emptyCGImage
    }
    
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
