/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The selective desaturator class file.
*/

import Cocoa
import Accelerate
import Combine
import SwiftUI
import simd

class SelectiveDesaturator: ObservableObject {

    /// The source image.
    let sourceImage =  #imageLiteral(resourceName: "sprinkles.png").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    /// An array that contains the red source pixels.
    ///
    /// The app uses this array to return the color selected color in the user interface.
    let sourcePixelsRed: [Float]
    
    /// An array that contains the green source pixels.
    ///
    /// The app uses this array to return the color selected color in the user interface.
    let sourcePixelsGreen: [Float]
    
    /// An array that contains the blue source pixels.
    ///
    /// The app uses this array to return the color selected color in the user interface.
    let sourcePixelsBlue: [Float]
    
    /// The Core Graphics image format for the source and destination Core Graphics image.
    var cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: kCGBitmapByteOrder32Host.rawValue |
                                 CGBitmapInfo.floatComponents.rawValue |
                                 CGImageAlphaInfo.none.rawValue))!
    
    /// The red, green, and blue planar buffers that contain the source image.
    let rgbSourceBuffers: [vImage.PixelBuffer<vImage.PlanarF>]
    
    /// The planar buffer that contains the destination red channel.
    let redDestinationBuffer: vImage.PixelBuffer<vImage.PlanarF>
    
    /// The planar buffer that contains the destination green channel.
    let greenDestinationBuffer: vImage.PixelBuffer<vImage.PlanarF>
    
    /// The planar buffer that contains the destination blue channel.
    let blueDestinationBuffer: vImage.PixelBuffer<vImage.PlanarF>
    
    /// The interleaved RGB buffer that contains the destination image.
    let interleavedDestinationBuffer: vImage.PixelBuffer<vImage.InterleavedFx3>

    /// The destination Core Graphics image.
    @Published var outputImage: CGImage
    
    /// The target color.
    ///
    /// The app desaturates or darkens colors that are dissimilar to this color.
    @Published var targetColor: CGColor = .black {
        didSet {
            self.applyLookupTable()
        }
    }
    
    /// A Boolean value that specifies whether the app should apply desaturation.
    @Published var desaturate = true {
        didSet {
            self.applyLookupTable()
        }
    }
    
    /// A Boolean value that specifies whether the app should apply darkening.
    @Published var darken = true {
        didSet {
            self.applyLookupTable()
        }
    }
    
    /// The tolerance for the desaturation and darkening effect.
    @Published var tolerance: Float = 100 {
        didSet {
            self.applyLookupTable()
        }
    }
    
    /// The number of color entries per axis of the lookup table.
    ///
    /// A high `entriesPerChannel` value provides greater color fidelity than a low value, but with a
    /// corresponding performance and memory overhead.
    let entriesPerChannel = UInt8(32)
    
    /// An array that contains `entriesPerChannel` values which form a ramp in the range `0...1`.
    let ramp: [Double]
    
    /// The number of source channels.
    let srcChannelCount = 3
    
    /// The number of destination channels.
    let destChannelCount = 3
    
    /// The buffer that contains the lookup table values.
    let lookupTableData: UnsafeMutableBufferPointer<UInt16>
  
    init() {
        outputImage = sourceImage
        
        let lookupTableElementCount = Int(pow(Float(entriesPerChannel),
                                              Float(srcChannelCount))) * Int(destChannelCount)
        
        lookupTableData = UnsafeMutableBufferPointer<UInt16>.allocate(capacity: lookupTableElementCount)
        
        let rgbSourceBuffer = try! vImage.PixelBuffer<vImage.InterleavedFx3>(
            cgImage: sourceImage,
            cgImageFormat: &cgImageFormat)
        
        rgbSourceBuffers = rgbSourceBuffer.planarBuffers()
        
        sourcePixelsRed = rgbSourceBuffers[0].array
        sourcePixelsGreen = rgbSourceBuffers[1].array
        sourcePixelsBlue = rgbSourceBuffers[2].array
        
        let size = vImage.Size(width: sourceImage.width, height: sourceImage.height)
        
        redDestinationBuffer = vImage.PixelBuffer<vImage.PlanarF>(size: size)
        greenDestinationBuffer = vImage.PixelBuffer<vImage.PlanarF>(size: size)
        blueDestinationBuffer = vImage.PixelBuffer<vImage.PlanarF>(size: size)
        interleavedDestinationBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(size: size)
        
        ramp = vDSP.ramp(in: 0 ... 1.0, count: Int(entriesPerChannel))
    }
    
    deinit {
        lookupTableData.deallocate()
    }
    
    func applyLookupTable() {

        if targetColor == .black {
            DispatchQueue.main.async { [self] in
                outputImage = sourceImage
            }
            return
        }
 
        guard let targetRGB = targetColor.components else {
            targetColor = .black
            applyLookupTable()
            return
        }

        let targetLabColor = ColorConverter.rgbToLab(red: targetRGB[0],
                                                     green: targetRGB.count > 1 ? targetRGB[1] : targetRGB[0],
                                                     blue: targetRGB.count > 2 ? targetRGB[2] : targetRGB[0])
        
        populateLookupTableData(targetLabColor: targetLabColor)

        let entryCountPerSourceChannel = [UInt8](repeating: entriesPerChannel,
                                                 count: srcChannelCount)
        
        let lookupTable = vImage.MultidimensionalLookupTable(
            entryCountPerSourceChannel: entryCountPerSourceChannel,
            destinationChannelCount: destChannelCount,
            data: lookupTableData)
        
        lookupTable.apply(sources: rgbSourceBuffers,
                          destinations: [ redDestinationBuffer,
                                          greenDestinationBuffer,
                                          blueDestinationBuffer ],
                          interpolation: .full)
        
        interleavedDestinationBuffer.interleave(planarSourceBuffers: [ redDestinationBuffer,
                                                                       greenDestinationBuffer,
                                                                       blueDestinationBuffer ])
        
        DispatchQueue.main.async { [self] in
            outputImage = interleavedDestinationBuffer.makeCGImage(cgImageFormat: cgImageFormat)!
        }
    }
    
    func populateLookupTableData(targetLabColor: simd_float3) {
        var bufferIndex = 0
        let multiplier = CGFloat(UInt16.max)
        for red in ramp {
            for green in ramp {
                for blue in ramp {
                   
                    let srcLabColor = ColorConverter.rgbToLab(red: red, green: green, blue: blue)
                    
                    let distance = simd_distance(targetLabColor, srcLabColor)
                    
                    let effectMultiplier = 1 - simd_smoothstep(0, tolerance, distance)
                    
                    let src = NSColor(red: red,
                                      green: green,
                                      blue: blue,
                                      alpha: 1)
                    
                    let dest = NSColor(hue: src.hueComponent,
                                       saturation: src.saturationComponent * (desaturate ? CGFloat(effectMultiplier) : 1),
                                       brightness: src.brightnessComponent * (darken ? CGFloat(effectMultiplier) : 1),
                                       alpha: 1)
                    
                    lookupTableData[ bufferIndex ] = UInt16(dest.redComponent * multiplier)
                    bufferIndex += 1
                    
                    lookupTableData[ bufferIndex ] = UInt16(dest.greenComponent * multiplier)
                    bufferIndex += 1
                    
                    lookupTableData[ bufferIndex ] = UInt16(dest.blueComponent * multiplier)
                    bufferIndex += 1
                }
            }
        }
    }
}

struct ColorConverter {

    static let labColorSpace = CGColorSpace(name: CGColorSpace.genericLab)!
    
    static let rgbToLabConverter = try! vImageConverter.make(
        sourceFormat: .init(bitsPerComponent: 32,
                            bitsPerPixel: 32 * 3,
                            colorSpace: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGBitmapInfo(
                              rawValue: kCGBitmapByteOrder32Host.rawValue |
                              CGBitmapInfo.floatComponents.rawValue |
                              CGImageAlphaInfo.none.rawValue))!,
        destinationFormat: .init(bitsPerComponent: 32,
                                 bitsPerPixel: 32 * 3,
                                 colorSpace: labColorSpace,
                                 bitmapInfo: CGBitmapInfo(
                                   rawValue: kCGBitmapByteOrder32Host.rawValue |
                                   CGBitmapInfo.floatComponents.rawValue |
                                   CGImageAlphaInfo.none.rawValue))!)
    
    static func rgbToLab(red: CGFloat, green: CGFloat, blue: CGFloat) -> simd_float3 {
        
        let srcPixelBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(
            pixelValues: [Float(red), Float(green), Float(blue)],
            size: .init(width: 1, height: 1))
        
        let dstPixelBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(
            size: .init(width: 1, height: 1))
        
        try! rgbToLabConverter.convert(from: srcPixelBuffer, to: dstPixelBuffer)
   
        return .init(dstPixelBuffer.array)
    }
}
