/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that generates video effects.
*/

import Accelerate
import AVFoundation
import Cocoa
import Combine

let pixelBufferSize = vImage.Size(width: 640, height: 480)
let sessionPreset = AVCaptureSession.Preset.vga640x480

class VideoEffectsEngine: NSObject, ObservableObject {
    
    @Published var outputImage: CGImage?
    @Published var effect = VideoEffects.passThrough
    
    enum VideoEffects: String, Identifiable, CaseIterable {
        case passThrough = "Pass Through"
        case noise = "Noise"
        case posterization = "Posterization"
        case temporalBlur = "Temporal Blur"
        case colorThreshold = "Color Threshold"
        
        var id: String { self.rawValue }
    }
    
    // MARK: Image formats and any-to-any converter.
    
    let cvImageFormat = vImageCVImageFormat.make(
        format: .format422YpCbCr8,
        matrix: kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4.pointee,
        chromaSiting: .center,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        alphaIsOpaqueHint: true)!
    
    let cgImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent)!
    
    lazy var converter: vImageConverter = {
        guard let converter = try? vImageConverter.make(
            sourceFormat: cvImageFormat,
            destinationFormat: cgImageFormat) else {
            fatalError("Unable to create converter")
        }
        
        return converter
    }()
    
    // MARK: Pixel Buffers.
    
    /// The destination buffer contains the source frame and the effect output.
    let destinationBuffer = vImage.PixelBuffer(
        size: pixelBufferSize,
        pixelFormat: vImage.InterleavedFx3.self)
    
    /// The buffer where the `applyTemporalBlur` function stores
    /// previous frames for the temporal blur effect.
    lazy var temporalBuffer = vImage.PixelBuffer(
        size: pixelBufferSize,
        pixelFormat: vImage.InterleavedFx3.self)
    
    /// The buffer that receives BNNS random values in the `applyNoise` function.
    lazy var noiseBuffer = vImage.PixelBuffer(
        size: pixelBufferSize,
        pixelFormat: vImage.InterleavedFx3.self)
    
    /// The multiple-plane pixel buffer that the `applyPosterization` uses
    /// to calculate and specify the histogram.
    lazy var histogramBuffer = vImage.PixelBuffer(
        size: pixelBufferSize,
        pixelFormat: vImage.PlanarFx3.self)
    
    // MARK: Constants
   
    let captureSession = AVCaptureSession()
    
    lazy var randomNumberGenerator = BNNSCreateRandomGenerator(
        BNNSRandomGeneratorMethodAES_CTR,
        nil)!
    
    // MARK: Methods
    
    override init() {
        super.init()

        configureCaptureSession()
    }
    
    /// Converts and copies the contents of `pixelBuffer` to `destinationBuffer`.
    func populateDestinationBuffer(pixelBuffer: CVPixelBuffer) {
        
        let sourceBuffer = vImage.PixelBuffer(
            referencing: pixelBuffer,
            converter: converter,
            destinationPixelFormat: vImage.DynamicPixelFormat.self)
        
        do {
            try converter.convert(
                from: sourceBuffer,
                to: destinationBuffer)
        } catch {
            fatalError("Any-to-any conversion failure.")
        }
    }
    
    /// Renders the contents of `destinationBuffer` to `outputImage`.
    func renderDestinationBuffer() {
        DispatchQueue.main.async {

            self.outputImage = self.destinationBuffer.makeCGImage(
                cgImageFormat: self.cgImageFormat)!
        }
    }
}

// MARK: Video Effects methods.

extension VideoEffectsEngine {
    /// Computes the linear interpolation between `destinationBuffer` and `temporalBuffer`,
    /// and writes the result to `destinationBuffer`.
    func applyTemporalBlur() {
        
        let interpolationConstant: Float = 0.925
        
        destinationBuffer.linearInterpolate(
            bufferB: temporalBuffer,
            interpolationConstant: interpolationConstant,
            destination: temporalBuffer)
        
        temporalBuffer.copy(to: destinationBuffer)
    }
    
    /// Applies random noise to `destinationBuffer`.
    ///
    /// This function populates the destination buffer with the element-wise
    /// sum of the existing pixel and random values that BNNS generates.
    func applyNoise() {
        
        noiseBuffer.withUnsafeMutableBufferPointer { noisePtr in
            
            if var descriptor = BNNSNDArrayDescriptor(
                data: noisePtr,
                shape: BNNS.Shape.tensor3DFirstMajor(
                    noiseBuffer.width,
                    noiseBuffer.height,
                    noiseBuffer.channelCount)) {
                
                /// Fill `noiseBuffer` with random values mapped to a normal distribution with a mean
                /// of `0` and a standard deviation of `0.125`.
                let mean: Float = 0
                let stdDev: Float = 0.125
                
                BNNSRandomFillNormalFloat(
                    randomNumberGenerator,
                    &descriptor,
                    mean,
                    stdDev)
            }
        }
        
        /// Fill `mutableDestinationPtr` with the sum of the corresponding pixels
        /// in `destinationBuffer` and `noiseBuffer`.
        destinationBuffer.withUnsafeMutableBufferPointer { mutablDestinationPtr in
            
            vDSP.add(destinationBuffer, noiseBuffer,
                     result: &mutablDestinationPtr)
        }
    }
    
    /// Applies a posterization effect to `destinationBuffer`.
    ///
    /// This function calculates the histogram of the destination buffer using four bins per channel.
    /// The function applies the histogram back to the destination buffer using the reduced bin
    /// count.
    func applyPosterization() {
        
        destinationBuffer.deinterleave(
            destination: histogramBuffer)
        
        let histogram = histogramBuffer.histogram(
            binCount: 4)
        
        histogramBuffer.specifyHistogram(
            histogram,
            destination: histogramBuffer)
        
        histogramBuffer.interleave(
            destination: destinationBuffer)
    }
    
    /// Applies a color threshold effect to `destinationBuffer`.
    ///
    /// This function sets channel values that are less than `0.5` to `0`; otherwise,
    /// the function sets the channel value to `1.0`.
    ///
    /// The function applies the threshold to each separate color channel. Therefore, the
    /// result contains a maximum of eight different colors: black, white, red, green, blue,
    /// cyan, yellow, and magenta.
    func applyColorThreshold() {
        
        let threshold: Float = 0.5
        
        destinationBuffer.colorThreshold(
            threshold,
            destination: destinationBuffer)
    }
}

// MARK: AVFoundation-related methods.

extension VideoEffectsEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func configureCaptureSession() {
        /// When running in macOS, you must add a "Privacy - Camera Usage
        /// Description" entry to `Info.plist`, and check
        /// "camera access" below the "Resource Access" category of "Hardened
        /// Runtime".
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
            /// Users can add authorization by choosing System Preferences >
            /// Security & Privacy > Camera on a macOS device.
            fatalError("App requires camera access.")
        }
        
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = sessionPreset
        
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
        
        populateDestinationBuffer(pixelBuffer: pixelBuffer)
  
        switch effect {
        case .passThrough:
            break
        case .noise:
            applyNoise()
        case .posterization:
            applyPosterization()
        case .temporalBlur:
            applyTemporalBlur()
        case .colorThreshold:
            applyColorThreshold()
        }
        
        renderDestinationBuffer()
        
        CVPixelBufferUnlockBaseAddress(
            pixelBuffer,
            CVPixelBufferLockFlags.readOnly)
    }
}
