/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The chroma key to alpha-channel conversion function file.
*/


import Accelerate
import Cocoa
import simd

extension ImageProvider {
    
    /// - Tag: chromaKeyToAlpha
    /// Returns a planar buffer that represents the alpha channel that the chroma key color defines.
    ///
    /// - Parameter source: The ARGB source buffer.
    /// - Parameter chromaKeyColor: The chroma-key color.
    /// - Parameter tolerance: The color tolerance that the function uses when calculating alpha values.
    static func chromaKeyToAlpha(source: vImage.PixelBuffer<vImage.InterleavedFx4>,
                                 chromaKeyColor: CGColor,
                                 tolerance: Float) -> vImage.PixelBuffer<vImage.PlanarF> {
        
        // Create the lookup table data.
        
        let entriesPerChannel = UInt8(32)
        let ramp = vDSP.ramp(in: 0 ... 1.0, count: Int(entriesPerChannel))
        
        let sourceChannelCount = 3
        let destinationChannelCount = 1
        
        let lookupTableElementCount = Int(pow(Float(entriesPerChannel),
                                              Float(sourceChannelCount))) * Int(destinationChannelCount)
        
        let lookupTableData = UnsafeMutableBufferPointer<UInt16>.allocate(capacity: lookupTableElementCount)
        defer {
            lookupTableData.deallocate()
        }
        
        let chromaKeyRGB = chromaKeyColor.components ?? [0, 0, 0]
        let chromaKeyLab = ColorConverter.rgbToLab(r: chromaKeyRGB[0],
                                                   g: chromaKeyRGB.count > 1 ? chromaKeyRGB[1] : chromaKeyRGB[0],
                                                   b: chromaKeyRGB.count > 2 ? chromaKeyRGB[2] : chromaKeyRGB[0])
        
        var bufferIndex = 0
        for red in ramp {
            for green in ramp {
                for blue in ramp {
                    
                    let lab = ColorConverter.rgbToLab(r: red, g: green, b: blue)
                    
                    let distance = simd_distance(chromaKeyLab, lab)
                    
                    let contrast = Float(20)
                    let offset = Float(0.25)
                    let alpha = saturate(tanh(((distance / tolerance ) - 0.5 - offset) * contrast))
                    
                    lookupTableData[bufferIndex] = UInt16(alpha * Float(UInt16.max))
                    bufferIndex += 1
                }
            }
        }
        
        // Create the multidimensional lookup table.
        
        let entryCountPerSourceChannel = [UInt8](repeating: entriesPerChannel,
                                                 count: sourceChannelCount)
        
        let lookupTable = vImage.MultidimensionalLookupTable(
            entryCountPerSourceChannel: entryCountPerSourceChannel,
            destinationChannelCount: destinationChannelCount,
            data: lookupTableData)
        
        let sourcePlanarBuffers: [vImage.PixelBuffer<vImage.PlanarF>] = source.planarBuffers()
        
        let destinationBuffer = vImage.PixelBuffer<vImage.PlanarF>(size: source.size)
        
        lookupTable.apply(sources: Array(sourcePlanarBuffers[ 1 ... 3 ]),
                          destinations: [ destinationBuffer ],
                          interpolation: .full)
        
        return destinationBuffer
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
    
    static func rgbToLab(r: CGFloat, g: CGFloat, b: CGFloat) -> simd_float3 {
        
        let srcPixelBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(
            pixelValues: [Float(r), Float(g), Float(b)],
            size: .init(width: 1, height: 1))
        
        let dstPixelBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(
            size: .init(width: 1, height: 1))
        
        try! rgbToLabConverter.convert(from: srcPixelBuffer, to: dstPixelBuffer)
        
        return .init(dstPixelBuffer.array)
    }
}

/// Returns `x` clamped to `0...1`.
func saturate<T: FloatingPoint>(_ x: T) -> T {
    return min(max(0, x), 1)
}
