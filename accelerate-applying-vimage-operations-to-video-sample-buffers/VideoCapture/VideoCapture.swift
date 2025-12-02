/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB converter class.
*/

import Accelerate
import AVFoundation
import SwiftUI

class VideoCapture: NSObject, ObservableObject {

    @Published var outputImage = VideoCapture.emptyCGImage
    @Published var isRunning = false
    @Published var info = "\n\n"
    
    var pixelFormat: FourCharCode = 0
    
    let captureSession = AVCaptureSession()
    let queue = DispatchQueue(label: "video data queue")
    
    override init() {
        super.init()
        
        configureCaptureSession()
    }
    
    // MARK: Video-format-to-RGB conversion.
    
    let cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue))!
    
    var converter: vImageConverter!
    
    var sourceBuffers: [vImage.PixelBuffer<vImage.DynamicPixelFormat>]!
    var destinationBuffer: vImage.PixelBuffer<vImage.Interleaved8x3>!
    
    func createConverter(cvPixelBuffer: CVPixelBuffer) {
        guard let cvImageFormat = vImageCVImageFormat.make(buffer: cvPixelBuffer) else {
            fatalError("Unable to derive Core Video pixel format from buffer.")
        }
        
        if cvImageFormat.colorSpace == nil {
            cvImageFormat.colorSpace = CGColorSpaceCreateDeviceRGB()
        }
        
        if cvImageFormat.chromaSiting == nil {
            cvImageFormat.chromaSiting = .center
        }
        
        converter = try? vImageConverter.make(sourceFormat: cvImageFormat,
                                              destinationFormat: cgImageFormat)
        
        if converter == nil {
            fatalError("Unable to create Core Video to Core Graphics converter.")
        }
    }
    
    @inlinable
    func convertVideoFormatToRGB(cvPixelBuffer: CVPixelBuffer) throws {

        if !isRunning {
            createConverter(cvPixelBuffer: cvPixelBuffer)
            
            let size = vImage.Size(cvPixelBuffer: cvPixelBuffer)
            destinationBuffer = vImage.PixelBuffer<vImage.Interleaved8x3>(size: size)
            
            DispatchQueue.main.async { [self] in
                info = Self.fourCharCodeToString(pixelFormat)
                info += "\n\(destinationBuffer.size.width) x \(destinationBuffer.size.height)"
                info += "\n\(converter.sourceBufferCount) source buffer\(converter.sourceBufferCount > 1 ? "s" : "")"
                isRunning = true
            }
        } else if converter == nil || destinationBuffer == nil {
            NSLog("Exited `convertVideoFormatToRGB` to prevent concurrent calls.")
            
            return
        }
        
        // `makeCVToCGPixelBuffers` calls `vImageBuffer_InitForCopyFromCVPixelBuffer`
        sourceBuffers = try converter.makeCVToCGPixelBuffers(referencing: cvPixelBuffer)
        
        try converter.convert(from: sourceBuffers, to: [destinationBuffer])
        
        let rgbImage = destinationBuffer.makeCGImage(cgImageFormat: cgImageFormat)!
        
        DispatchQueue.main.async { [self] in
            outputImage = rgbImage
        }
    }
    
    func stopRunning() {
        queue.async {
            self.captureSession.stopRunning()
        }
        
    }
}

// MARK: AVFoundation-related methods.

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func configureCaptureSession() {
        /// When running in macOS, you must add a "Privacy - Camera Usage
        /// Description" entry to `Info.plist`, and check
        /// QUERY: By check, do you mean to select a checkbox?
        /// "camera access" below the Resource Access category of Hardened
        /// Runtime.
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
                /// Users can add authorization on a macOS computer by choosing System Settings >
                /// Privacy & Security > Camera.
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
            fatalError("Unable to create AVCaptureDeviceInput.")
        }

        let videoOutput = AVCaptureVideoDataOutput()

        videoOutput.setSampleBufferDelegate(self,
                                            queue: queue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("Unable to add video output.")
        }

        pixelFormat = CMFormatDescriptionGetMediaSubType(camera.activeFormat.formatDescription)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat]
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
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
        
        do {
            try convertVideoFormatToRGB(cvPixelBuffer: pixelBuffer)
        } catch {
            fatalError("Unable to perform conversion.")
        }
        
        CVPixelBufferUnlockBaseAddress(
            pixelBuffer,
            CVPixelBufferLockFlags.readOnly)
    }
}

extension VideoCapture {
    /// A 1x1 Core Graphics image.
    static var emptyCGImage: CGImage = {
        let buffer = vImage.PixelBuffer(
            pixelValues: [200],
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
    
    static func fourCharCodeToString(_ fcc: FourCharCode) -> String {
        let x = Character(UnicodeScalar(fcc >> 24 & 0xFF)!)
        let y = Character(UnicodeScalar(fcc >> 16 & 0xFF)!)
        let z = Character(UnicodeScalar(fcc >> 8 & 0xFF)!)
        let w = Character(UnicodeScalar(fcc >> 0 & 0xFF)!)
        
        return String([x, y, z, w])
    }
}
