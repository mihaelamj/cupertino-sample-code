/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sceneKit recorder that records the rendering to a HEVC alpha based movie.
*/

import Cocoa
import SceneKit
import AVFoundation
import VideoToolbox

struct ExportSettings {
    static let duration = CMTime(value: 5, timescale: 1)
    static let frameRate = CMTimeScale(60)
    static let height = 720
    static let width = 1280
    static let viewport = CGRect(x: 0, y: 0, width: width, height: height)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SCNSceneRendererDelegate {
    @IBOutlet weak var sceneKitView: SCNView!
    @IBOutlet weak var recordDest: NSTextField!
    @IBOutlet weak var recordButton: NSButton!
    
    var scene: SCNScene {
        return sceneKitView.scene!
    }
    
    // Metal Rendering
    let renderer = SCNRenderer(device: nil, options: nil)
    var lampMaterials: SCNNode!
    var metalTextureCache: CVMetalTextureCache!
    
    // Export
    var frameCounter = 0
    
    // MARK: SceneKit/Metal Rendering
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var err: OSStatus
        
        // Setup Scene renderer
        renderer.scene = scene
        renderer.delegate = self
        
        // Retrieve the lamp node to animate
        lampMaterials = scene.rootNode.childNode(
            withName: "lamp",
            recursively: true)
        
        // Setup metal texture cache
        var optionalMetalTextureCache: CVMetalTextureCache?
        err = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            renderer.device!,
            nil,
            &optionalMetalTextureCache)
        if err != kCVReturnSuccess || optionalMetalTextureCache == nil {
            fatalError("Cannot create metal texture cache: \(err)")
        }
        metalTextureCache = optionalMetalTextureCache
    }
    
    /// Render next frame and call the frame completion handler
    func renderNextFrameAsynchronously(using pool: CVPixelBufferPool,
                                       handleFrameCompletion: @escaping (_ pixelBuffer: CVPixelBuffer?, _ presentationTime: CMTime) -> Void) {
        var err = noErr
        let currentPresentationTime = CMTime(value: CMTimeValue(frameCounter), timescale: ExportSettings.frameRate)
        if currentPresentationTime >= ExportSettings.duration {
            // No more frames to render.
            handleFrameCompletion(nil, .zero)
            return
        }
        frameCounter += 1
        
        // Create a new CVPixelBuffer from the pool
        // The pool gets initialized as part of asset writer initialization.
        var optionalPixelBuffer: CVPixelBuffer?
        err = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            pool,
            &optionalPixelBuffer)
        guard err == noErr, let pixelBuffer = optionalPixelBuffer else {
            fatalError("Failed to create a pixel buffer from pixel buffer pool: \(err).")
        }
        
        // Create a Metal texture wrapping pixelBuffer
        let pixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        var optionalMetalTexture: CVMetalTexture?
        err = CVMetalTextureCacheCreateTextureFromImage( kCFAllocatorDefault, metalTextureCache, pixelBuffer,
                                                         nil,
                                                         pixelFormat,
                                                         ExportSettings.width,
                                                         ExportSettings.height,
                                                         0,
                                                         &optionalMetalTexture)
        guard err == noErr, let metalTexture = optionalMetalTexture else {
            fatalError("Failed to create a metal texture from pixel buffer: \(err).")
        }
        
        // Render the frame on a clear background
        let commandBuffer = renderer.commandQueue!.makeCommandBuffer()!
        let clearColor = MTLClearColorMake(0, 0, 0, 0)
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].texture = CVMetalTextureGetTexture(metalTexture)
        renderer.render(atTime: currentPresentationTime.seconds,
                        viewport: ExportSettings.viewport,
                        commandBuffer: commandBuffer,
                        passDescriptor: renderPassDescriptor)
        commandBuffer.addCompletedHandler { _ in
            handleFrameCompletion(pixelBuffer, currentPresentationTime)
        }
        commandBuffer.commit()
    }
    
    /// SceneKit Render update call back (per frame)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let angle = CGFloat(Double.pi * 2 * time / ExportSettings.duration.seconds)
        lampMaterials.eulerAngles = SCNVector3(x: 0, y: angle, z: 0)
    }
    
    // MARK: AssetWriting
    func makeAssetWriter(outputURL: URL, fileType: AVFileType) throws ->
        (assetWriter: AVAssetWriter, writerInput: AVAssetWriterInput, adaptor: AVAssetWriterInputPixelBufferAdaptor) {
            let assetWriter = try AVAssetWriter( outputURL: outputURL, fileType: fileType)
            
            /*
             Video with alpha contains base and alpha layers.
             Base layer works with variable bitrate encoding, and Alpha layer works with fixed quality encoding.
             Alpha layer will ignore bitrate settings.
             Optionally specify base layer bitrate, if you want precise bitrate encoding for base layer.
             Optionally specify alpha layer quality, if you want to fine-tune the quality of the alpha layer.
             */
            let alphaQuality = 0.5
            let outputSettings = [
                AVVideoCodecKey: AVVideoCodecType.hevcWithAlpha,
                AVVideoWidthKey: ExportSettings.width,
                AVVideoHeightKey: ExportSettings.height,
                AVVideoCompressionPropertiesKey:
                    [kVTCompressionPropertyKey_TargetQualityForAlpha: alphaQuality]
                ] as [String: Any]
            let videoWriter = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            videoWriter.expectsMediaDataInRealTime = false
            
            let pixelBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey: ExportSettings.width,
                kCVPixelBufferHeightKey: ExportSettings.height,
                kCVPixelBufferMetalCompatibilityKey: true] as [String: Any]
            
            let videoAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriter,
                sourcePixelBufferAttributes: pixelBufferAttributes)
            
            assetWriter.add(videoWriter)
            
            return (assetWriter: assetWriter, writerInput: videoWriter, adaptor: videoAdaptor)
    }
    
    /// Start an export and call completion handler when export is finished
    func exportToHEVCMovieWithAlphaAsynchronously(_ movieURL: URL, _ completionHandler: @escaping () -> Void ) throws {
        // Clear the output file and setup asset writer
        try? FileManager.default.removeItem(at: movieURL)
        let (assetWriter, videoTrackWriter, pixelBufferAdaptor ) = try makeAssetWriter(outputURL: movieURL, fileType: AVFileType.mov)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        // Reset frame counter before writing.
        frameCounter = 0
        
        // Start Writing
        let mediaDataRequestQueue = DispatchQueue(label: "com.apple.apple-samplecode.HEVC-Videos-With-Alpha-AssetWriting.mediaDataRequestQueue")
        videoTrackWriter.requestMediaDataWhenReady(on: mediaDataRequestQueue) {
            while videoTrackWriter.isReadyForMoreMediaData {
                // Ask metal to render the next frame and wait for it to complete
                let pendingFrame = DispatchSemaphore(value: 0)
                let pixelBufferPoolForRendering = pixelBufferAdaptor.pixelBufferPool!
                self.renderNextFrameAsynchronously(using: pixelBufferPoolForRendering) { resultFrame, presentationTime in
                    if let renderedFrame = resultFrame {
                        let success = pixelBufferAdaptor.append(renderedFrame, withPresentationTime: presentationTime)
                        if success == false {
                            print("Failed to write pixel buffer.")
                            fatalError()
                        }
                    } else {
                        // Finish writing.
                        assetWriter.inputs.forEach { $0.markAsFinished() }
                        assetWriter.endSession(atSourceTime: ExportSettings.duration)
                        assetWriter.finishWriting() {
                            if let error = assetWriter.error {
                                print("Failed to export movie: \(error). ")
                            } else {
                                print("Finished exporting movie to \(assetWriter.outputURL).")
                            }
                            CVMetalTextureCacheFlush(self.metalTextureCache, 0)
                            completionHandler()
                        }
                    }
                    pendingFrame.signal()
                }
                // Wait for the frame to be rendered and written
                // before proceeding to the next one.
                pendingFrame.wait()
            }
        }
    }
    
    // MARK: UI
    
    @IBAction func pressedRecord(_ sender: NSButton) {
        let destinationURL = URL(fileURLWithPath: recordDest.stringValue) // Destination File
        recordButton.isHighlighted = true
        recordButton.isEnabled = false
        recordDest.isEditable = false
        recordDest.isEnabled = false
        DispatchQueue.global(qos: .default).async {
            do {
                try self.exportToHEVCMovieWithAlphaAsynchronously(destinationURL) {
                    DispatchQueue.main.async {
                        self.recordButton.isHighlighted = false
                        self.recordButton.isEnabled = true
                        self.recordDest.isEditable = true
                        self.recordDest.isEnabled = true
                    }
                }
            } catch {
                print("Unexpected error: \(error).")
                return
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
