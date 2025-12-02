/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper type that processes pixel buffers.
*/

import AVFoundation
import CoreImage.CIFilterBuiltins

enum CompositorError: String, Error {
    case invalidSource = "Source does not have taggedBuffers nor pixelBuffer"
    case spatialVideoEditingNotSupported = "The OS does not support spatial video editing"
    case failedToCreateNewOutputPixelBuffer = "Failed to create new output pixel buffer"
}

struct PixelBufferHelper {
    static func filterPixelBufferWithColorInverter(_ pixelBuffer: CVReadOnlyPixelBuffer?, to outPixelBuffer: CVPixelBuffer) {
        if let pixelBuffer {
            let inputImage = pixelBuffer.withUnsafeBuffer { unsafePixelBuffer in
                CIImage(cvImageBuffer: unsafePixelBuffer)
            }
            let filter = CIFilter(name: "CIColorInvert")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            if let outputImage = filter?.outputImage {
                let context = CIContext()
                let bounds = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(outPixelBuffer), height: CVPixelBufferGetHeight(outPixelBuffer))
                context.render(outputImage, to: outPixelBuffer, bounds: bounds, colorSpace: nil)
            }
        }
    }

    static func diffPixelBuffers(a pixelBufferA: CVReadOnlyPixelBuffer, b pixelBufferB: CVReadOnlyPixelBuffer, to outputPixelBuffer: CVPixelBuffer) {
        let imageA = pixelBufferA.withUnsafeBuffer { unsafePixelBuffer in
            CIImage(cvImageBuffer: unsafePixelBuffer)
        }
        let imageB = pixelBufferB.withUnsafeBuffer { unsafePixelBuffer in
            CIImage(cvImageBuffer: unsafePixelBuffer)
        }
        let filter = CIFilter.colorAbsoluteDifference()
        filter.inputImage = imageA
        filter.inputImage2 = imageB
        if let outputImage = filter.outputImage {
            let context = CIContext()
            let bounds = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(outputPixelBuffer), height: CVPixelBufferGetHeight(outputPixelBuffer))
            context.render(outputImage, to: outputPixelBuffer, bounds: bounds, colorSpace: nil)
        }
    }

    static func findLeftAndRightEyePixelBuffers(in taggedBuffers: [CMTaggedDynamicBuffer]) -> (CVReadOnlyPixelBuffer?, CVReadOnlyPixelBuffer?) {
        var leftSourcePixelBuffer: CVReadOnlyPixelBuffer? = nil
        var rightSourcePixelBuffer: CVReadOnlyPixelBuffer? = nil
        for taggedBuffer in taggedBuffers {
            if taggedBuffer.tags.contains(.stereoView(.leftEye)) {
                guard case let .pixelBuffer(inputPixelBuffer) = taggedBuffer.content else {
                    return (nil, nil)
                }
                leftSourcePixelBuffer = inputPixelBuffer
            } else if taggedBuffer.tags.contains(.stereoView(.rightEye)) {
                guard case let .pixelBuffer(inputPixelBuffer) = taggedBuffer.content else {
                    return (nil, nil)
                }
                rightSourcePixelBuffer = inputPixelBuffer
            }
        }
        return (leftSourcePixelBuffer, rightSourcePixelBuffer)
    }
}
