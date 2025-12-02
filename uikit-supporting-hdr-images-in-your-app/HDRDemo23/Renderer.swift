/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The underlying rendering engine for the Core Image-based editing flow.
*/

import Foundation
import CoreImage
import CoreVideo
import ImageIO
import UniformTypeIdentifiers

class Renderer {

    let queue = DispatchQueue(label: "render")
    let pool: CVPixelBufferPool? = nil
    let context = CIContext(options: [.name: "Renderer"])

    // Use the image.colorspace as a destination space, if possible.
    // CIImages with applied filters may report the .colorspace property as nil
    // to indicate that the image is in the Core Image working colorpsace.
    // Provide a 'destinationColorspace' to use when this is the case.
    func render(_ image: CIImage, destinationColorspace: CGColorSpace?) async -> CVPixelBuffer? {

        let width = Int(image.extent.size.width)
        let height = Int(image.extent.size.height)

        let colorspaceName = String(destinationColorspace?.name ?? "")
        
        return await withUnsafeContinuation { continuation in
            queue.async { [context] in
                let transferFunction: CFString

                if colorspaceName.contains("HLG") {
                    transferFunction = kCVImageBufferTransferFunction_ITU_R_2100_HLG
                } else {
                    transferFunction = kCVImageBufferTransferFunction_SMPTE_ST_2084_PQ
                }
                
                // Use appropriate CVPixelBuffer options to ensure HDR support.
                let attributes: [CFString: Any] = [
                    kCVPixelBufferIOSurfacePropertiesKey: [CFString: Any]() as CFDictionary,
                    kCVPixelBufferMetalCompatibilityKey: true as CFNumber
                ]
                var buffer: CVPixelBuffer! = nil
                // Use the memory-efficient HDR-capable pixel format.
                let result = CVPixelBufferCreate(nil,
                                                 width,
                                                 height,
                                                 kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
                                                 attributes as CFDictionary,
                                                 &buffer)
                
                guard result == kCVReturnSuccess else {
                    print("Failed to allocate the pixel buffer.")
                    return continuation.resume(returning: nil)
                }
                
                // Set and propogate the colorspace on the pixel buffer.
                let colorAttachments: [CFString: Any] = [
                    kCVImageBufferYCbCrMatrixKey: kCVImageBufferYCbCrMatrix_ITU_R_2020,
                    kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_ITU_R_2020,
                    kCVImageBufferTransferFunctionKey: transferFunction
                ]
                
                CVBufferSetAttachments(buffer, colorAttachments as CFDictionary, .shouldPropagate)
                let destination = CIRenderDestination(pixelBuffer: buffer)
                do {
                    let task = try context.startTask(toRender: image, to: destination)
                    try task.waitUntilCompleted()
                } catch {
                    print("Failed to render image: \(image), error: \(error)")
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: buffer)
            }
        }
    }

    func export(_ image: CIImage, to file: URL, type: UTType?, colorspace: CGColorSpace?) -> Bool {

        let cgImage = context.createCGImage(image,
                                            from: image.extent,
                                            format: .RGB10,
                                            colorSpace: colorspace ?? CGColorSpace(name: CGColorSpace.itur_2100_PQ)!,
                                            deferred: true)

        guard let cgImage = cgImage else {
            print("Failed to create CGImage.")
            return false
        }

        let typeId = (type ?? UTType(filenameExtension: file.pathExtension) ?? UTType.heic).identifier

        guard let destination = CGImageDestinationCreateWithURL(file as CFURL, typeId as CFString, 1, nil) else {
            print("Failed to create CGImageDestination.")
            return false
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        return CGImageDestinationFinalize(destination)

    }

    func export(_ image: CIImage, contentType: UTType, colorspace: CGColorSpace?) -> Data? {

        let pqColorspace = CGColorSpace(name: CGColorSpace.itur_2100_PQ)!

        switch contentType {
        case .heic:
            return try? context.heif10Representation(of: image,
                                                     colorSpace: colorspace ?? pqColorspace)
        case .png:
            return context.pngRepresentation(of: image,
                                             format: .RGBA16,
                                             colorSpace: colorspace ?? pqColorspace)
        default:
            print("Cannot write this file type.")
            return nil
        }

    }

}
