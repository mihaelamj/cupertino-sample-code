/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB converter class.
*/


import Accelerate
import AVFoundation

class YUVtoRGBConverter: NSObject, ObservableObject {
    
    @Published var outputImage = {
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
    
    @Published var contrast: Float = 1
    
    // Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).
    static let cvPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    
    var argbPixelBuffer: vImage.PixelBuffer<vImage.Interleaved8x4>!
    
    let captureSession = AVCaptureSession()
    
    override init() {
        super.init()

        configureYpCbCrToARGBInfo()
        configureCaptureSession()
    }
    
    var infoYpCbCrToARGB = vImage_YpCbCrToARGB()
    
    func configureYpCbCrToARGBInfo() {
        var pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 16,
                                                 CbCr_bias: 128,
                                                 YpRangeMax: 235,
                                                 CbCrRangeMax: 240,
                                                 YpMax: 235,
                                                 YpMin: 16,
                                                 CbCrMax: 240,
                                                 CbCrMin: 16)

        var ypCbCrToARGBMatrix = vImage_YpCbCrToARGBMatrix(Yp: 1.0,
                                                           Cr_R: 1.402, Cr_G: -0.7141363,
                                                           Cb_G: -0.3441363, Cb_B: 1.772)
        
        _ = vImageConvert_YpCbCrToARGB_GenerateConversion(
            &ypCbCrToARGBMatrix,
            &pixelRange,
            &infoYpCbCrToARGB,
            kvImage422CbYpCrYp8,
            kvImageARGB8888,
            vImage_Flags(kvImageNoFlags))
    }
    
    var cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue))!
    
    func convertYpCbCrToRGB(cvPixelBuffer: CVPixelBuffer) {
        assert(CVPixelBufferGetPlaneCount(cvPixelBuffer) == 2, "Pixel buffer should have two planes.")
        
        if argbPixelBuffer == nil {
            argbPixelBuffer = vImage.PixelBuffer(width: CVPixelBufferGetWidthOfPlane(cvPixelBuffer, 0),
                                                 height: CVPixelBufferGetHeightOfPlane(cvPixelBuffer, 0),
                                                 pixelFormat: vImage.Interleaved8x4.self)
        }

        let lumaPixelBuffer = vImage.PixelBuffer(referencing: cvPixelBuffer,
                                                 planeIndex: 0,
                                                 pixelFormat: vImage.Planar8.self)
   
        let chromaPixelBuffer = vImage.PixelBuffer(referencing: cvPixelBuffer,
                                                   planeIndex: 1,
                                                   pixelFormat: vImage.Interleaved8x2.self)
        
        if contrast != 1 {
            lumaPixelBuffer.applyGamma(.halfPrecision(contrast),
                                       destination: lumaPixelBuffer)
        }
        
            
        argbPixelBuffer.convert(lumaSource: lumaPixelBuffer,
                                chromaSource: chromaPixelBuffer,
                                conversionInfo: infoYpCbCrToARGB)
        
        let argbImage = argbPixelBuffer.makeCGImage(cgImageFormat: cgImageFormat)!
        
        DispatchQueue.main.async {
            self.outputImage = argbImage
        }
    }
}

// MARK: AVFoundation-related methods.

extension YUVtoRGBConverter: @unchecked Sendable {}

extension YUVtoRGBConverter: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func configureCaptureSession() {
        /// When running in macOS, you need to add a "Privacy - Camera Usage
        /// Description" entry to `Info.plist`, and select the
        /// Camera Access option below the Resource Access category of Hardened
        /// Runtime in the Signing & Capabilities pane.
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(
                for: .video,
                completionHandler: { granted in
                    if !granted {
                        fatalError("App requires camera access.")
                    } else {
                        self.configureCaptureSession()
                    }
                })
            return
        default:
            /// People can give permission by choosing System Settings >
            /// Privacy & Security > Camera on a macOS device.
            fatalError("App requires camera access.")
        }
        
        captureSession.beginConfiguration()

        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("Can't create default camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            fatalError("Can't create AVCaptureDeviceInput.")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        let dataOutputQueue = DispatchQueue(label: "video data queue",
                                            qos: .userInteractive,
                                            attributes: [],
                                            autoreleaseFrequency: .workItem)
  
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: YUVtoRGBConverter.cvPixelFormat]
      
        videoOutput.setSampleBufferDelegate(self,
                                            queue: dataOutputQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            captureSession.commitConfiguration()
            captureSession.startRunning()
        } else {
            fatalError("Unable to add video output.")
        }
    }
   
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return
        }
     
        CVPixelBufferLockBaseAddress(
            pixelBuffer,
            CVPixelBufferLockFlags.readOnly)
        
        convertYpCbCrToRGB(cvPixelBuffer: pixelBuffer)
  
        CVPixelBufferUnlockBaseAddress(
            pixelBuffer,
            CVPixelBufferLockFlags.readOnly)
    }
}
