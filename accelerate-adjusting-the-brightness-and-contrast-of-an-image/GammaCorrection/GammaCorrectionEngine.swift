/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that applies gamma correction.
*/

import Accelerate
import AVFoundation
import Cocoa
import Combine

class GammaCorrectionEngine: ObservableObject {
    
    static let presets = [
        ResponseCurvePreset(id: "L1",
                            boundary: 255,
                            linearScale: 1,
                            linearBias: 0,
                            gamma: 0),
        ResponseCurvePreset(id: "L2",
                            boundary: 255,
                            linearScale: 0.5,
                            linearBias: 0.5,
                            gamma: 0),
        ResponseCurvePreset(id: "L3",
                            boundary: 255,
                            linearScale: 3,
                            linearBias: -1,
                            gamma: 0),
        ResponseCurvePreset(id: "L4",
                            boundary: 255,
                            linearScale: -1,
                            linearBias: 1,
                            gamma: 0),
        ResponseCurvePreset(id: "E1",
                            boundary: 0,
                            linearScale: 1,
                            linearBias: 0,
                            gamma: 1),
        ResponseCurvePreset(id: "E2",
                            boundary: 0,
                            linearScale: 1,
                            linearBias: 0,
                            gamma: 2.2),
        ResponseCurvePreset(id: "E3",
                            boundary: 0,
                            linearScale: 1,
                            linearBias: 0,
                            gamma: 1 / 2.2)
    ]
    
    let sourceImage = #imageLiteral(resourceName: "Food_4.JPG").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    var imageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent)!
    
    let sourceBuffer: vImage.PixelBuffer<vImage.Interleaved8x3>
    let destinationBuffer: vImage.PixelBuffer<vImage.Interleaved8x3>
    
    @Published var outputImage: CGImage
    
    @Published var responseCurvePreset: ResponseCurvePreset {
        didSet {
            // When the user changes the response curve preset, the app applies the
            // appropriate piecewise gamma values to the source buffer and writes
            // the result to the destination buffer.
            outputImage = Self.getGammaCorrectedImage(
                preset: responseCurvePreset,
                source: sourceBuffer,
                destination: destinationBuffer,
                imageFormat: imageFormat)
        }
    }
    
    init() {
        do {
            sourceBuffer = try vImage.PixelBuffer(
                cgImage: sourceImage,
                cgImageFormat: &imageFormat,
                pixelFormat: vImage.Interleaved8x3.self)
        } catch {
            fatalError("Unable to create pixel buffer from image.")
        }
        
        destinationBuffer = vImage.PixelBuffer(
            size: sourceBuffer.size,
            pixelFormat: vImage.Interleaved8x3.self)
        
        responseCurvePreset = Self.presets[0]
        
        outputImage = Self.getGammaCorrectedImage(
            preset: Self.presets[0],
            source: sourceBuffer,
            destination: destinationBuffer,
            imageFormat: imageFormat)
    }
    
    /// Applies the piecewise gamma values that the preset specifies to the source buffer, writes the result to the
    /// destination buffer, and returns the destination buffer's contents as an image.
    static func getGammaCorrectedImage(
        preset: ResponseCurvePreset,
        source: vImage.PixelBuffer<vImage.Interleaved8x3>,
        destination: vImage.PixelBuffer<vImage.Interleaved8x3>,
        imageFormat: vImage_CGImageFormat) -> CGImage {

            let linearCoefficients = (preset.linearScale, preset.linearBias)
            
            let exponentialCoefficients = (Float(1), Float(0), preset.gamma, Float(0))
            
            source.applyGamma(linearParameters: linearCoefficients,
                              exponentialParameters: exponentialCoefficients,
                              boundary: preset.boundary,
                              destination: destination)
            
            if let result = destination.makeCGImage(cgImageFormat: imageFormat) {
                return result
            } else {
                fatalError("Unable to generate output image.")
            }
        }
}

/// A structure that wraps piecewise gamma parameters.
struct ResponseCurvePreset: Hashable, Identifiable {
    let id: String
    let boundary: Pixel_8
    let linearScale: Float
    let linearBias: Float
    let gamma: Float
}
