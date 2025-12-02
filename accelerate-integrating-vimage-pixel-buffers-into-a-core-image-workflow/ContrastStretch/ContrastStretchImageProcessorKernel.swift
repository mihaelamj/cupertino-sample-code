/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The ends-in contrast-stretching image processor kernel.
*/

import Accelerate
import CoreImage

class ContrastStretchImageProcessorKernel: CIImageProcessorKernel {
    
    enum ContrastStretchImageProcessorKernelError: Error {
        case contrastStretchOperationFailed
        case vImageConverterCreationFailed
        case unableToDeriveImageFormat
        case illegalParameters
    }
    
    static var cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .defaultIntent)
    
    override class var outputFormat: CIFormat {
        return CIFormat.BGRA8
    }
    
    override class func formatForInput(at input: Int32) -> CIFormat {
        return CIFormat.BGRA8
    }

    override class func process(with inputs: [CIImageProcessorInput]?,
                                arguments: [String: Any]?,
                                output: CIImageProcessorOutput) throws {
        
        guard
            let input = inputs?.first,
            let inputPixelBuffer = input.pixelBuffer,
            let outputPixelBuffer = output.pixelBuffer else {
                return
        }
        
        let percentLow = arguments?["percentLow"] as? Int ?? 0
        let percentHigh = arguments?["percentHigh"] as? Int ?? 0
        
        if percentLow + percentHigh > 100 {
            throw ContrastStretchImageProcessorKernelError.illegalParameters
        }
        
        CVPixelBufferLockBaseAddress(inputPixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(inputPixelBuffer,
                                           CVPixelBufferLockFlags.readOnly)
        }
        
        guard let cvImageFormat = vImageCVImageFormat.make(buffer: inputPixelBuffer) else {
            throw ContrastStretchImageProcessorKernelError.unableToDeriveImageFormat
        }
        
        if cvImageFormat.colorSpace == nil {
            cvImageFormat.colorSpace = CGColorSpaceCreateDeviceRGB()
        }
        
        guard let converter = try? vImageConverter.make(
            sourceFormat: cvImageFormat,
            destinationFormat: cgImageFormat) else {
            throw ContrastStretchImageProcessorKernelError.vImageConverterCreationFailed
        }
        
        let sourcePixelBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
            referencing: inputPixelBuffer,
            converter: converter)
        
        CVPixelBufferLockBaseAddress(outputPixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(outputPixelBuffer,
                                           CVPixelBufferLockFlags.readOnly)
        }
        
        let destinationPixelBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
            referencing: outputPixelBuffer,
            converter: converter)
        
        let error = sourcePixelBuffer.withUnsafePointerToVImageBuffer { src in
            destinationPixelBuffer.withUnsafePointerToVImageBuffer { dst in

                return vImageEndsInContrastStretch_ARGB8888(
                    src,
                    dst,
                    [UInt32](repeating: UInt32(percentLow), count: 4),
                    [UInt32](repeating: UInt32(percentHigh), count: 4),
                    vImage_Flags(kvImageNoFlags))
                
            }
        }
        
        guard error == kvImageNoError else {
            throw ContrastStretchImageProcessorKernelError.contrastStretchOperationFailed
        }
    }
}

