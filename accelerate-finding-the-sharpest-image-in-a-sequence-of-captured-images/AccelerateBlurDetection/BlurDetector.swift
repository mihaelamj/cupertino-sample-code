/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The blur detection class.
*/

import AVFoundation
import Accelerate
import UIKit
import SwiftUI
import Combine

// MARK: BlurDetector
class BlurDetector: NSObject, ObservableObject {
    let laplacian: [Float] = [-1, -1, -1,
                              -1,  8, -1,
                              -1, -1, -1]
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    weak var resultsDelegate: BlurDetectorResultsDelegate?
    
    var processedCount = 0
    
    func configure() {
        
        let sessionQueue = DispatchQueue(label: "session queue")
        
        sessionQueue.async {
            self.configureSession(sessionQueue: sessionQueue)
        }
    }
    
    private func configureSession(sessionQueue: DispatchQueue) {
        captureSession.beginConfiguration()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.sessionPreset = .hd1280x720
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        fatalError("App requires camera access.")
                    }
                    sessionQueue.resume()
                    return
                })
            default:
                fatalError("App requires camera access.")
        }
        
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .back),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Can't create camera.")
        }
        
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
    }
    
    func takePhoto() {
        let pixelFormat: FourCharCode = {
            if photoOutput.availablePhotoPixelFormatTypes
                .contains(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
                return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            } else if photoOutput.availablePhotoPixelFormatTypes
                .contains(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
                return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            } else {
                fatalError("No available YpCbCr formats.")
            }
        }()
        
        let exposureSettings = (0 ..< photoOutput.maxBracketedCapturePhotoCount).map { _ in
            AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(
                exposureTargetBias: AVCaptureDevice.currentExposureTargetBias)
        }
        
        let photoSettings = AVCapturePhotoBracketSettings(
            rawPixelFormatType: 0,
            processedFormat: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat],
            bracketedSettings: exposureSettings)
        
        processedCount = 0
        
        photoOutput.capturePhoto(with: photoSettings,
                                 delegate: self)
    }
    
    /// Creates a grayscale `CGImage` from an 8- or 32-bit planar buffer.
    ///
    /// - Parameter sourceBuffer: The vImage containing the image data.
    /// - Parameter orientation: The orientation of of the image.
    ///
    /// - Returns: A grayscale Core Graphics image.
    static func makeImage<Format>(fromPlanarBuffer sourceBuffer: vImage.PixelBuffer<Format>,
                                  orientation: CGImagePropertyOrientation) -> CGImage?
    where Format: StaticPixelFormat {
        var outputBuffer: vImage.PixelBuffer<Format>
        var outputRotation: Int
        
        if orientation == .right || orientation == .left {
            outputBuffer = vImage.PixelBuffer<Format>(width: sourceBuffer.height,
                                                      height: sourceBuffer.width)
            
            outputRotation = orientation == .right ?
                    kRotate90DegreesClockwise : kRotate90DegreesCounterClockwise
        } else if orientation == .up || orientation == .down {
            outputBuffer = vImage.PixelBuffer<Format>(width: sourceBuffer.width,
                                                      height: sourceBuffer.height)
            outputRotation = orientation == .down ?
                    kRotate180DegreesClockwise : kRotate0DegreesClockwise
        } else {
            return nil
        }
        
        let imageFormat: vImage_CGImageFormat
        
        let rotateFunction: (UnsafePointer<vImage_Buffer>,
                             UnsafePointer<vImage_Buffer>,
                             UInt8) -> vImage_Error
        
        if Format.self == vImage.Planar8.self {
            imageFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: .init(rawValue: CGImageAlphaInfo.none.rawValue))!
            
            func rotate (src: UnsafePointer<vImage_Buffer>,
                         dst: UnsafePointer<vImage_Buffer>,
                         rotation: UInt8) -> vImage_Error {
                vImageRotate90_Planar8(src, dst, rotation, 0, 0)
            }
            rotateFunction = rotate
        } else if Format.self == vImage.PlanarF.self {
            imageFormat = vImage_CGImageFormat(
                bitsPerComponent: 32,
                bitsPerPixel: 32,
                colorSpace: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue:
                                            kCGBitmapByteOrder32Host.rawValue |
                                            CGBitmapInfo.floatComponents.rawValue |
                                            CGImageAlphaInfo.none.rawValue))!
            
            func rotate (src: UnsafePointer<vImage_Buffer>,
                         dst: UnsafePointer<vImage_Buffer>,
                         rotation: UInt8) -> vImage_Error {
                vImageRotate90_PlanarF(src, dst, rotation, 0, 0)
            }
            rotateFunction = rotate
        } else {
            fatalError("This function only supports Planar8 and PlanarF formats.")
        }
        
        sourceBuffer.withUnsafePointerToVImageBuffer { src in
            outputBuffer.withUnsafePointerToVImageBuffer { dst in
                _ = rotateFunction(src, dst, UInt8(outputRotation))
            }
        }
        
        return outputBuffer.makeCGImage(cgImageFormat: imageFormat)
    }
}

// MARK: BlurDetector AVCapturePhotoCaptureDelegate extension

extension BlurDetector: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        if let error = error {
            fatalError("Error capturing photo: \(error).")
        }
        
        guard let pixelBuffer = photo.pixelBuffer else {
            fatalError("Error acquiring pixel buffer.")
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer,
                                     CVPixelBufferLockFlags.readOnly)
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let count = width * height
        
        let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let lumaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        let lumaCopy = UnsafeMutableRawPointer.allocate(
            byteCount: count,
            alignment: MemoryLayout<Pixel_8>.alignment)
        lumaCopy.copyMemory(from: lumaBaseAddress!,
                            byteCount: count)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer,
                                       CVPixelBufferLockFlags.readOnly)
        
        Task(priority: .utility) {
            self.processImage(data: lumaCopy,
                              rowBytes: lumaRowBytes,
                              width: width,
                              height: height,
                              sequenceCount: photo.sequenceCount,
                              expectedCount: photo.resolvedSettings.expectedPhotoCount,
                              orientation: photo.metadata[ String(kCGImagePropertyOrientation) ] as? UInt32)
            
            lumaCopy.deallocate()
        }
    }
    
    func processImage(data: UnsafeMutableRawPointer,
                      rowBytes: Int,
                      width: Int, height: Int,
                      sequenceCount: Int,
                      expectedCount: Int,
                      orientation: UInt32? ) {
        
        let imageBuffer = vImage.PixelBuffer(data: data,
                                             width: width,
                                             height: height,
                                             byteCountPerRow: rowBytes,
                                             pixelFormat: vImage.Planar8.self)
        
        var laplacianStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: width * height)
        let laplacianBuffer = vImage.PixelBuffer(data: laplacianStorage.baseAddress!,
                                                 width: width,
                                                 height: height,
                                                 byteCountPerRow: width * MemoryLayout<Float>.stride,
                                                 pixelFormat: vImage.PlanarF.self)
        defer {
            laplacianStorage.deallocate()
        }
        
        imageBuffer.convert(to: laplacianBuffer)
        
        vDSP.convolve(laplacianStorage,
                      rowCount: height,
                      columnCount: width,
                      with3x3Kernel: laplacian,
                      result: &laplacianStorage)
        
        let variance = laplacianBuffer.variance
        
        // Apply a gamma function to the Laplacian result to improve its visibility
        // in the user interface.
        laplacianBuffer.applyGamma(.sRGBReverseHalfPrecision, destination: laplacianBuffer)
        
        if
            let orientation = orientation,
            let imageOrientation = CGImagePropertyOrientation(rawValue: orientation),
            let laplacianImage = Self.makeImage(fromPlanarBuffer: laplacianBuffer,
                                                orientation: imageOrientation),
            let grayscaleImage = Self.makeImage(fromPlanarBuffer: imageBuffer,
                                                orientation: imageOrientation) {
            
            let result = BlurDetectionResult(index: sequenceCount,
                                             image: grayscaleImage,
                                             laplacianImage: laplacianImage,
                                             score: variance)
            
            print("index \(sequenceCount) : score \(variance)")
            
            DispatchQueue.main.async {
                self.processedCount += 1
                self.resultsDelegate?.itemProcessed(result)
                
                if self.processedCount == expectedCount {
                    self.resultsDelegate?.finishedProcessing()
                }
            }
        }
    }
}

extension AccelerateMutableBuffer where Element == Float {
    var variance: Float {
        
        var mean = Float.nan
        var standardDeviation = Float.nan
        
        self.withUnsafeBufferPointer {
            vDSP_normalize($0.baseAddress!, 1,
                           nil, 1,
                           &mean, &standardDeviation,
                           vDSP_Length(self.count))
        }
        
        return standardDeviation * standardDeviation
    }
}

// MARK: BlurDetectorResultsDelegate protocol

protocol BlurDetectorResultsDelegate: AnyObject {
    func itemProcessed(_ item: BlurDetectionResult)
    func finishedProcessing()
}

// MARK: BlurDetectionResult

struct BlurDetectionResult {
    let index: Int
    let image: CGImage
    let laplacianImage: CGImage
    let score: Float
}

// Extensions to simplify conversion between orientation enums.
extension UIImage.Orientation {
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(_ uiInterfaceOrientation: UIInterfaceOrientation) {
        switch uiInterfaceOrientation {
        case .unknown:
            return nil
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        @unknown default:
            return nil
        }
    }
}
