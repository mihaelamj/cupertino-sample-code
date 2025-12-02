/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Classes for custom video composition.
*/

import CoreMedia
import AVFoundation
import Cinematic

// MARK: - SampleCompositionInstruction
/// A composition instruction that contains the state `SampleCustomCompositor` uses to render a cinematic asset.
final class SampleCompositionInstruction: NSObject {

    let renderingSession: CNRenderingSession
    let compositionInfo: CNCompositionInfo
    let script: CNScript
    let fNumber: Float
    let editMode: Bool

    init(renderingSession: CNRenderingSession,
         compositionInfo: CNCompositionInfo,
         script: CNScript, fNumber: Float, editMode: Bool) {
        self.renderingSession = renderingSession
        self.compositionInfo = compositionInfo
        self.script = script
        self.fNumber = fNumber
        self.editMode = editMode
    }
}

// MARK: - AVVideoCompositionInstructionProtocol Conformance
extension SampleCompositionInstruction: AVVideoCompositionInstructionProtocol {

    var enablePostProcessing: Bool {
        false
    }

    var containsTweening: Bool {
        true
    }

    var passthroughTrackID: CMPersistentTrackID {
        kCMPersistentTrackID_Invalid
    }

    var requiredSourceTrackIDs: [NSValue]? {
        compositionInfo.videoCompositionTracks.map { $0.trackID as NSNumber }
    }

    var requiredSourceSampleDataTrackIDs: [NSNumber] {
        compositionInfo.sampleDataTrackIDs.map { $0 as NSNumber }
    }

    var timeRange: CMTimeRange {
        compositionInfo.timeRange
    }
}

final class SampleCustomCompositor: NSObject, AVVideoCompositing {

    var supportsHDRSourceFrames = true
    var supportsWideColorSourceFrames = true

    let cinematicEditHelper = CinematicEditHelper(device: MTLCreateSystemDefaultDevice()!)

    var sourcePixelBufferAttributes: [String: Any]? {
        let pixelFormats = CNRenderingSession.sourcePixelFormatTypes

        // Request buffer allocation using IOSurface.
        return [kCVPixelBufferPixelFormatTypeKey as String: pixelFormats,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
            ]
    }

    var requiredPixelBufferAttributesForRenderContext: [String: Any] {
        // `CNRenderingSession` supports `CNRenderingSession.destinationPixelFormatTypes` for the output destination.
        // Sample Custom Compositor uses `kCVPixelFormatType_64RGBAHalf` from supported pixel formats.
        let pixelFormats = [kCVPixelFormatType_64RGBAHalf]

        // Request buffer allocation using IOSurface.
        return [kCVPixelBufferPixelFormatTypeKey as String: pixelFormats,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
            ]
    }

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {

        guard let instruction: SampleCompositionInstruction = request.videoCompositionInstruction as? SampleCompositionInstruction else {
            fatalError("Unexpected instruction type")
        }
        
        let cinematicCompositionInfo = instruction.compositionInfo
        let renderingSession = instruction.renderingSession
        let cinematicScript = instruction.script

        // Request the output buffer.
        guard let outputBuffer = request.renderContext.newPixelBuffer() else {
            fatalError("No output buffer")
        }
        
        // Get the source frame buffers.
        guard let sourceFrame = SourceFrame(request: request, cinematicCompositionInfo: cinematicCompositionInfo) else { return }

        let sessionAttributes = renderingSession.sessionAttributes
        // Get the frame attributes associated with the metadata buffer.
        guard var frameAttributes = CNRenderingSession.FrameAttributes(sampleBuffer: sourceFrame.metadataBuffer,
                                                sessionAttributes: sessionAttributes) else {
            fatalError("Failed to get frame attributes")
        }

        // Use `fNumber` from `instruction` (optional).
        frameAttributes.fNumber = instruction.fNumber

        // Find the nearest frame for focus disparity (optional).
        let frameTime: CMTime = request.compositionTime
        let tolerance = request.renderContext.videoComposition.frameDuration
        if let frame = cinematicScript.frame(at: frameTime, tolerance: tolerance) {
            frameAttributes.focusDisparity = frame.focusDisparity
        }

        // Get the command buffer for the encoder and rectangle drawing.
        guard let commandBuffer = renderingSession.commandQueue.makeCommandBuffer() else {
            fatalError("No command buffer")
        }

        // Request rendering with changed frame attributes.
        renderingSession.encodeRender(to: commandBuffer, frameAttributes: frameAttributes,
                                      sourceImage: sourceFrame.imageBuffer, sourceDisparity: sourceFrame.disparityBuffer,
                                      destinationImage: outputBuffer)

        // Show focus detections, if requested.
        if instruction.editMode {
            drawFocusDetections(frameTime: frameTime,
                                tolerance: tolerance,
                                outputBuffer: outputBuffer,
                                commandBuffer: commandBuffer,
                                instruction: instruction)
        }

        // Set up the command buffer completion handler.
        commandBuffer.addCompletedHandler { commandBuffer in
            guard commandBuffer.status == .completed else {
                fatalError("Command buffer failed to complete")
            }
            request.finish(withComposedVideoFrame: outputBuffer)
        }
        // Commit the command buffer.
        commandBuffer.commit()
    }
}

extension SampleCustomCompositor {
    private func drawFocusDetections(frameTime: CMTime,
                                     tolerance: CMTime,
                                     outputBuffer: CVPixelBuffer,
                                     commandBuffer: MTLCommandBuffer,
                                     instruction: SampleCompositionInstruction) {
        
        let cinematicScript = instruction.script
        
        if let cinematicScriptFrame = cinematicScript.frame(at: frameTime, tolerance: tolerance) {

            var strongDecision = false

            // Find out if the decision is strong or weak.
            if let decision = cinematicScript.decision(at: cinematicScriptFrame.time, tolerance: CMTime.zero) {
                strongDecision = decision.isStrongDecision
            } else {
                if let decision = cinematicScript.decision(before: frameTime) {
                    strongDecision = decision.isStrongDecision
                }
            }

            // Draw rectangles.
            cinematicEditHelper.drawRectsForCNScriptFrame(cinematicScriptFrame: cinematicScriptFrame,
                                                          outputBuffer: outputBuffer,
                                                          strongDecision: strongDecision,
                                                          rectDrawCommandBuffer: commandBuffer,
                                                          preferredTransform: instruction.renderingSession.preferredTransform)
        }
    }
}

extension SampleCustomCompositor {
    
    private struct SourceFrame {
        let imageBuffer: CVPixelBuffer
        let disparityBuffer: CVPixelBuffer
        let metadataBuffer: CMSampleBuffer
        
        init?(request: AVAsynchronousVideoCompositionRequest, cinematicCompositionInfo: CNCompositionInfo) {
            // Get video, disparity, and metadata buffers.
            guard let imageBuffer = request.sourceFrame(byTrackID: cinematicCompositionInfo.cinematicVideoTrack.trackID) else {
                print("No video pixel buffer")
                request.finishCancelledRequest()
                return nil
            }
            guard let disparityBuffer = request.sourceFrame(byTrackID: cinematicCompositionInfo.cinematicDisparityTrack.trackID) else {
                print("No disparity buffer")
                request.finish(withComposedVideoFrame: imageBuffer)
                return nil
            }
            guard let metadataBuffer = request.sourceSampleBuffer(byTrackID: cinematicCompositionInfo.cinematicMetadataTrack.trackID) else {
                print("No metabuffer")
                request.finish(withComposedVideoFrame: imageBuffer)
                return nil
            }
            
            self.imageBuffer = imageBuffer
            self.disparityBuffer = disparityBuffer
            self.metadataBuffer = metadataBuffer
        }
    }
    
}
