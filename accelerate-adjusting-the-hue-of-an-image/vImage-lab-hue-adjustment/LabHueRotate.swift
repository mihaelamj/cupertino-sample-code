/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class responsible for hue adjustment in the L*a*b* color space app.
*/

import Cocoa
import Accelerate
import Combine

class LabHueRotate: ObservableObject {
    
    @Published var hueAngle: Float = 0
    
    @Published var outputImage: CGImage

    let sourceCGImage: CGImage
    
    var labImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 3,
        colorSpace: CGColorSpace(name: CGColorSpace.genericLab)!,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent)!
    
    /// The interleaved pixel buffer that stores the original image in L\*a\*b\* color space.
    private var labInterleavedSource: vImage.PixelBuffer<vImage.Interleaved8x3>
    
    /// The interleaved pixel buffer that stores the hue-adjusted image in L\*a\*b\* color space.
    private var labInterleavedDestination: vImage.PixelBuffer<vImage.Interleaved8x3>
    
    /// The multiple-plane pixel buffer that stores the hue-adjusted image in L\*a\*b\* color space.
    private var labPlanarDestination: vImage.PixelBuffer<vImage.Planar8x3>

    var cancellable: AnyCancellable?
    
    init(image: NSImage) {
        guard
            let sourceCGImage = image.cgImage(forProposedRect: nil,
                                              context: nil,
                                              hints: nil) else {
            fatalError("Unable to generate a `CGImage` from the `NSImage`.")
        }
                  
        self.sourceCGImage = sourceCGImage
        outputImage = sourceCGImage

        let size = vImage.Size(width: sourceCGImage.width,
                               height: sourceCGImage.height)
        
        labInterleavedSource = vImage.PixelBuffer<vImage.Interleaved8x3>(size: size)
        labInterleavedDestination = vImage.PixelBuffer<vImage.Interleaved8x3>(size: size)
        labPlanarDestination = vImage.PixelBuffer<vImage.Planar8x3>(size: size)
        
        do {
            let source = try vImage.PixelBuffer
                .makeDynamicPixelBufferAndCGImageFormat(cgImage: sourceCGImage)
            
            let rgbToLab = try vImageConverter.make(sourceFormat: source.cgImageFormat,
                                                    destinationFormat: labImageFormat)
            
            try rgbToLab.convert(from: source.pixelBuffer,
                                 to: labInterleavedSource)
        } catch {
            fatalError("Any-to-any conversion failed.")
        }
        
        cancellable = $hueAngle
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { _ in
                self.applyAdjustment()
            }
        
        applyAdjustment()
    }
 
    func applyAdjustment() {
        let divisor: Int = 0x1000
        
        let rotationMatrix = [
            1, 0,             0,
            0, cos(hueAngle), -sin(hueAngle),
            0, sin(hueAngle),  cos(hueAngle)
        ].map {
            return Int($0 * Float(divisor))
        }
        
        let preBias = [Int](repeating: -128, count: 3)
        let postBias = [Int](repeating: 128 * divisor, count: 3)
      
        labInterleavedSource.deinterleave(destination: labPlanarDestination)
        
        labPlanarDestination.multiply(
            by: rotationMatrix,
            divisor: divisor,
            preBias: preBias,
            postBias: postBias,
            destination: labPlanarDestination)
        
        labPlanarDestination.interleave(destination: labInterleavedDestination)
        
        if let result = labInterleavedDestination
            .makeCGImage(cgImageFormat: labImageFormat) {
            
            DispatchQueue.main.async {
                self.outputImage = result
            }
        }
    }
}

