/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MorphologyTransformer class that applies morphology-based bokeh simulation.
*/

import SwiftUI
import Combine
import Cocoa
import Accelerate
import simd

class MorphologyTransformer: ObservableObject {
    
    /// The number of edges on the bokeh polygon.
    @Published var diaphragmBladeCount = 6.0 {
        didSet {
            Task(priority: .userInitiated) {
                await applyBokeh()
            }
        }
    }
    
    /// The radius of the bokeh polygon.
    @Published var bokehRadius = 10.0 {
        didSet {
            Task(priority: .userInitiated) {
                await applyBokeh()
            }
        }
    }
    
    /// The starting angle of the bokeh polygon.
    @Published var angle = Angle(degrees: 0) {
        didSet {
            Task(priority: .userInitiated) {
                await applyBokeh()
            }
        }
    }
    
    /// The output image.
    @Published var outputImage: CGImage
    
    /// A Core Graphics image that represents the bokeh polygon shape.
    @Published var structuringElementImage = MorphologyTransformer.emptyCGImage
    
    /// The Core Graphics image format that the sample app uses to display the output image.
    var rgbImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent)!
    
    /// The Core Graphics image format that the sample app uses to display the bokeh polygon shape.
    var monoImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent)!
    
    /// The source pixel buffers.
    let sourceRedBuffer: vImage.PixelBuffer<vImage.Planar8>
    let sourceGreenBuffer: vImage.PixelBuffer<vImage.Planar8>
    let sourceBlueBuffer: vImage.PixelBuffer<vImage.Planar8>
    
    /// The destination pixel buffers.
    let destinationRGBBuffer: vImage.PixelBuffer<vImage.Interleaved8x3>
    let destinationRedBuffer: vImage.PixelBuffer<vImage.Planar8>
    let destinationGreenBuffer: vImage.PixelBuffer<vImage.Planar8>
    let destinationBlueBuffer: vImage.PixelBuffer<vImage.Planar8>
    
    /// Creates a new morphology transformer instance from the supplied image.
    init(sourceImage: NSImage) {
        
        guard
            let image = sourceImage.cgImage(forProposedRect: nil,
                                            context: nil,
                                            hints: nil),
            let sourceRGBBuffer = try? vImage.PixelBuffer<vImage.Interleaved8x3>(
                cgImage: image,
                cgImageFormat: &rgbImageFormat) else {
            fatalError("Unable to parse source image.")
        }
        
        outputImage = image

        sourceRedBuffer = .init(size: sourceRGBBuffer.size)
        sourceGreenBuffer = .init(size: sourceRGBBuffer.size)
        sourceBlueBuffer = .init(size: sourceRGBBuffer.size)
        
        destinationRGBBuffer = .init(size: sourceRGBBuffer.size)
        destinationRedBuffer = .init(size: sourceRGBBuffer.size)
        destinationGreenBuffer = .init(size: sourceRGBBuffer.size)
        destinationBlueBuffer = .init(size: sourceRGBBuffer.size)
        
        sourceRGBBuffer.deinterleave(planarDestinationBuffers: [sourceRedBuffer,
                                                                sourceGreenBuffer,
                                                                sourceBlueBuffer])
        
        Task {
            await applyBokeh()
        }
    }

    /// Creates a structuring element based on the diaphragm blade count, bokeh radius, and starting
    /// angle. Then concurrently uses the structuring element to apply a dilation operation to each of the
    /// red, green, and blue planar pixel buffers.
    func applyBokeh() async {
        
        await withTaskGroup(of: Void.self) { group in
            
            let bokeh = Self.makeBokehStructuringElement(ofRadius: Int(bokehRadius),
                                                         atAngle: angle,
                                                         withSides: Int(diaphragmBladeCount))
            
            /// Generate the bokeh polygon preview image.
            group.addTask(priority: .userInitiated) { [self] in
                let diameter = (Int(bokehRadius) * 2) + 1
                let bokehBuffer = vImage.PixelBuffer<vImage.Planar8>(pixelValues: bokeh.values,
                                                                     size: .init(width: diameter,
                                                                                 height: diameter))
                
                DispatchQueue.main.async { [self] in
                    structuringElementImage = bokehBuffer.makeCGImage(cgImageFormat: monoImageFormat)!
                }
            }
            
            /// Apply dilation to the red channel.
            group.addTask(priority: .userInitiated) { [self] in
                sourceRedBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                                destination: destinationRedBuffer)
            }
            
            /// Apply dilation to the green channel.
            group.addTask(priority: .userInitiated) { [self] in
                sourceGreenBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                                  destination: destinationGreenBuffer)
            }
            
            /// Apply dilation to the blue channel.
            group.addTask(priority: .userInitiated) { [self] in
                sourceBlueBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                                 destination: destinationBlueBuffer)
            }
        }

        /// Interleave the three destination planar buffers.
        destinationRGBBuffer.interleave(planarSourceBuffers: [destinationRedBuffer,
                                                              destinationGreenBuffer,
                                                              destinationBlueBuffer])
        
        /// Display the RGB morphology result.
        DispatchQueue.main.async { [self] in
            outputImage = destinationRGBBuffer.makeCGImage(cgImageFormat: rgbImageFormat)!
        }
    }
    
    /// - Tag: makeStructuringElement
    /// Returns a `vImage.StructuringElement` that represents a polygon with properties that the
    /// `radius`, `startAngle`, and `sides` parameters define.
    static func makeBokehStructuringElement(ofRadius radius: Int,
                                            atAngle startAngle: Angle,
                                            withSides sides: Int) -> vImage.StructuringElement<Pixel_8> {

        let diameter = (radius * 2) + 1
        
        var values = [Pixel_8](repeating: 255,
                             count: diameter * diameter)
        
        let angle = ((Float.pi * 2) / Float(sides))
        
        /// Draw the outer border of the polygon.
        var previousVertex: simd_float2?
        stride(from: Float(startAngle.radians),
               through: (.pi * 2) + Float(startAngle.radians),
               by: angle).forEach {
            
            let x = Float(radius) + sin($0) * (Float(radius) - 0.01)
            let y = Float(radius) + cos($0) * (Float(radius) - 0.01)
            
            if let start = previousVertex {
                let end = simd_float2(Float(x), Float(y))
                let delta = 1.0 / max(abs(start.x - end.x), abs(start.y - end.y))
                
                stride(from: Float(0), through: Float(1), by: delta).forEach { t in
                    let coord = simd_mix(start, end, simd_float2(repeating: t))
                    
                    values[(Int(round(coord.x)) + Int(round(coord.y)) * diameter)] = 0
                }
            }
            
            previousVertex = simd_float2(Float(x), Float(y))
        }
        
        /// Create a temporary `vImage_Buffer` that shares data with the structuring element values,
        /// and call `vImageFloodFill_Planar8` to fill the polygon.
        values.withUnsafeMutableBufferPointer { ptr in
            var buffer = vImage_Buffer(data: ptr.baseAddress!,
                                       height: vImagePixelCount(diameter),
                                       width: vImagePixelCount(diameter),
                                       rowBytes: diameter * MemoryLayout<Pixel_8>.stride)
            
            vImageFloodFill_Planar8(&buffer, nil,
                                    vImagePixelCount(radius), vImagePixelCount(radius),
                                    0,
                                    4,
                                    vImage_Flags(kvImageNoFlags))
        }
        
        return .init(values: values, width: diameter, height: diameter)
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
