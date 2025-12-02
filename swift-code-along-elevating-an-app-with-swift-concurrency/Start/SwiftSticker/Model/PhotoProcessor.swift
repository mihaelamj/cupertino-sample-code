/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model that extracts a mask and dominant colors from a source image to create a destination image and color scheme.
*/

import SwiftUI
import PhotosUI
import Vision
import CoreImage.CIFilterBuiltins

struct PhotoProcessor {

    let colorExtractor = ColorExtractor()

    func process(data: Data) -> ProcessedPhoto? {
        let sticker = extractSticker(from: data)
        let colors = extractColors(from: data)

        guard let sticker = sticker, let colors = colors else { return nil }

        return ProcessedPhoto(sticker: sticker, colorScheme: colors)
    }

    private func extractColors(from data: Data) -> PhotoColorScheme? {
        return colorExtractor.extractColors(from: data)
    }

    private func extractSticker(from data: Data) -> Image? {
        guard let image = CIImage(data: data) else { return nil }

        let handler = VNImageRequestHandler(ciImage: image)
        let request = VNGenerateForegroundInstanceMaskRequest()

        do {
            try handler.perform([request])

            guard let result = request.results?.first else { return nil }

            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            let mask = CIImage(cvPixelBuffer: maskPixelBuffer)
            let extent = mask.extent

            let minDimension = min(extent.width, extent.height)
            let scaledRadius = max(1, Int(minDimension * 0.02))

            let dilatedMask = mask
                .applyingFilter("CIMorphologyMaximum", parameters: [
                    "inputRadius": scaledRadius
                ])

            let whiteBackground = CIImage(color: .white)
                .cropped(to: extent)
                .applyingFilter("CIBlendWithMask", parameters: [
                    "inputMaskImage": dilatedMask
                ])

            let subject = image
                .applyingFilter("CIBlendWithMask", parameters: [
                    "inputMaskImage": mask
                ])

            let sticker = subject.composited(over: whiteBackground)

            guard let cgImage = CIContext()
                .createCGImage(sticker, from: sticker.extent) else {
                return nil
            }
            return Image(decorative: cgImage, scale: 1.0)
        } catch {
            print("Unable to extract foreground: \(error)")
            return nil
        }
    }
}
