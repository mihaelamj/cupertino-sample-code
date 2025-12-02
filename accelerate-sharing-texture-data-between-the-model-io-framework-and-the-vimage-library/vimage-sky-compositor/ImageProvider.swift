/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sky compositor class.
*/

import ModelIO
import Accelerate
import Cocoa

/// - Tag: ImageProvider
class ImageProvider: ObservableObject {
    
    let sourceImage = #imageLiteral(resourceName: "City_11.png")
    
    static let options: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]
    static let views = ["+X", "-X", "+Y", "-Y", "+Z", "-Z"]
    
    @Published var outputImage: CGImage = emptyCGImage
    
    @Published var isBusy = false
    
    @Published var turbidity: Float = 1 {
        didSet {
            renderSky()
        }
    }
    
    @Published var sunElevation: Float = 0.5 {
        didSet {
            renderSky()
        }
    }
    
    @Published var upperAtmosphereScattering: Float = 1 {
        didSet {
            renderSky()
        }
    }
    
    @Published var groundAlbedo: Float = 0 {
        didSet {
            renderSky()
        }
    }
    
    @Published var view: String = views[5] {
        didSet {
            renderSky()
        }
    }
    
    var format: vImage_CGImageFormat
    
    let foregroundBuffer: vImage.PixelBuffer<vImage.Interleaved8x4>
    
    let width: Int
    var height: Int
    
    let skyGenerator: MDLSkyCubeTexture
    
    init() {
        format = vImage_CGImageFormat(bitsPerComponent: 8,
                                      bitsPerPixel: 8 * 4,
                                      colorSpace: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: .init(rawValue: CGImageAlphaInfo.first.rawValue))!
        
        let foregroundImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        foregroundBuffer = try! vImage.PixelBuffer(cgImage: foregroundImage,
                                                   cgImageFormat: &format,
                                                   pixelFormat: vImage.Interleaved8x4.self)
        
        width = foregroundImage.width
        height = foregroundImage.height
        
        skyGenerator = MDLSkyCubeTexture(name: nil,
                                         channelEncoding: .uInt8,
                                         textureDimensions: .init(x: Int32(width),
                                                                  y: Int32(height)),
                                         turbidity: 0,
                                         sunElevation: 0,
                                         upperAtmosphereScattering: 0,
                                         groundAlbedo: 0)
        
        renderSky()
    }
    
    /// - Tag: renderSky
    func renderSky() {
        isBusy = true
        Task {
            skyGenerator.turbidity = turbidity
            skyGenerator.sunElevation = sunElevation
            skyGenerator.upperAtmosphereScattering = upperAtmosphereScattering
            skyGenerator.groundAlbedo = groundAlbedo
            
            skyGenerator.update()
            
            let img = skyGenerator.texelDataWithTopLeftOrigin()?.withUnsafeBytes { skyData in
                
                let imageIndex = ImageProvider.views.firstIndex(of: view) ?? 0
                let imagePixelCount = width * height * format.componentCount
                
                let range = imageIndex * imagePixelCount ..< (imageIndex + 1) * imagePixelCount
                
                let values = skyData.bindMemory(to: Pixel_8.self)[ range ]
                
                let buffer = vImage.PixelBuffer(pixelValues: values,
                                                size: .init(width: width, height: height),
                                                pixelFormat: vImage.Interleaved8x4.self)

                buffer.permuteChannels(to: (3, 0, 1, 2), destination: buffer)
                
                buffer.alphaComposite(.nonpremultiplied,
                                      topLayer: foregroundBuffer,
                                      destination: buffer)
                
                return buffer.makeCGImage(cgImageFormat: format)
            } // Ends `skyGenerator.texelDataWithTopLeftOrigin()?.withUnsafeBytes`.
            
            await MainActor.run {
                outputImage = img!
                isBusy = false
            }
        }
    }
    
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
