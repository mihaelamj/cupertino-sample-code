/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that contains utilities to draw rectangles from a Cinematic mode script frame.
*/

import CoreMedia
import AVFoundation
import Cinematic
import Metal
import CoreImage
import CoreGraphics
import VideoToolbox
import CoreVideo
import AVKit
import OSLog

class CinematicEditHelper {
    let textureCache: CVMetalTextureCache
    let renderPipelineState: MTLRenderPipelineState

    init(device: MTLDevice) {
        
        var metalTextureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &metalTextureCache)
        
        guard let metalTextureCache else {
            fatalError("Couldn't create metal texture cache")
        }
        
        textureCache = metalTextureCache

        do {
            if let metalLibrary = device.makeDefaultLibrary() {
                // Set up the offline render pipeline for drawing rectangles.
                let vertexFunction = metalLibrary.makeFunction(name: "vertexShader")
                let fragmentFunction = metalLibrary.makeFunction(name: "fragmentShader")
                let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
                pipelineStateDescriptor.label = "Render Pipeline"
                pipelineStateDescriptor.vertexFunction = vertexFunction
                pipelineStateDescriptor.fragmentFunction = fragmentFunction
                pipelineStateDescriptor.vertexBuffers[0].mutability = .immutable
                pipelineStateDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
                renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
            } else {
                fatalError("Couldn't load metal library")
            }
        } catch {
            fatalError("Couldn't initialize shader function")
        }
    }
    
    private func texture(from outputBuffer: CVPixelBuffer) -> MTLTexture? {
        var image: CVMetalTexture?
        
        let width = CVPixelBufferGetWidth(outputBuffer)
        let height = CVPixelBufferGetHeight(outputBuffer)
        
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, outputBuffer, nil, .rgba16Float, width, height, 0, &image)
        
        guard let image else { return nil }
        
        let texture = CVMetalTextureGetTexture(image)
        
        return texture
    }

    func drawRectsForCNScriptFrame(cinematicScriptFrame: CNScript.Frame,
                                   outputBuffer: CVPixelBuffer,
                                   strongDecision: Bool,
                                   rectDrawCommandBuffer: MTLCommandBuffer,
                                   preferredTransform: CGAffineTransform) {
        
        if let texture = texture(from: outputBuffer) {
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            guard let renderEncoder =
                    rectDrawCommandBuffer.makeRenderCommandEncoder(
                        descriptor: renderPassDescriptor) else {
                fatalError("Couldnt create render command encoder")
            }
            
            renderEncoder.setRenderPipelineState(renderPipelineState)
            
            let whiteColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
            let yellowColor = SIMD4<Float>(1.0, 1.0, 0.0, 1.0)
            let focusRectThickness = SIMD2<Float>(5 / Float(texture.width), 5 / Float(texture.height))
            let nonFocusRectThickness = SIMD2<Float>(2 / Float(texture.width), 2 / Float(texture.height))

            // Get the focus rectangle.
            let focusDetection = cinematicScriptFrame.focusDetection
            let focusRect = focusDetection.normalizedRect
            let textureSize = CGSize(width: texture.width, height: texture.height)
            // Transform the rectangle.
            let transformedRect = applyTransform(rect: focusRect,
                                                 preferredTransform: preferredTransform,
                                                 textureSize: textureSize)
            // Draw the focus rectangle.
            drawRects(renderEncoder: renderEncoder, color: yellowColor,
                      rect: transformedRect, strongDecision: strongDecision,
                      thickness: focusRectThickness)
            // Go over the remaining detections, and draw only human faces.
            let allDetections = cinematicScriptFrame.allDetections
            
            for detection in allDetections {
                
                let rect = detection.normalizedRect
                
                if detection.detectionID != focusDetection.detectionID {
                    switch detection.detectionType {
                    case .humanFace, .humanHead, .humanTorso:
                        let transformedRect = applyTransform(rect: rect,
                                                             preferredTransform: preferredTransform,
                                                             textureSize: textureSize)
                        drawRects(renderEncoder: renderEncoder, color: whiteColor,
                                  rect: transformedRect, strongDecision: false,
                                  thickness: nonFocusRectThickness)
                    default:
                        break
                    }
                }
            }
            renderEncoder.endEncoding()
        } else {
            fatalError("No destination texture")
        }
    }

    // Transform the rectangle.
    func applyTransform(rect: CGRect, preferredTransform: CGAffineTransform, textureSize: CGSize) -> CGRect {
        let textureSizeRect = CGRect(origin: .zero, size: textureSize)
        let inverseTransform = CGAffineTransformInvert(preferredTransform)
        let transformedTextureSize = CGRectApplyAffineTransform(textureSizeRect, inverseTransform).size
        let textureRect = CGRect(x: rect.origin.x * transformedTextureSize.width,
                                 y: rect.origin.y * transformedTextureSize.height,
                                 width: rect.width * transformedTextureSize.width,
                                 height: rect.height * transformedTextureSize.height)
        let transformedRect = CGRectApplyAffineTransform(textureRect, preferredTransform)
        let finalRect = CGRect(x: transformedRect.origin.x / textureSize.width,
                             y: transformedRect.origin.y / textureSize.height,
                             width: transformedRect.width / textureSize.width,
                             height: transformedRect.height / textureSize.height)
        return finalRect
    }

    // Strong-decision rectangle.
    func drawStrongDecionRect(renderEncoder: MTLRenderCommandEncoder,
                              color: simd_float4, rect: CGRect,
                              thickness: simd_float2) {
        var edgeRect = CGRect.zero
        // Left edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y
        edgeRect.size.width = CGFloat(thickness.x)
        edgeRect.size.height = rect.size.height + CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Top edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y + rect.size.height
        edgeRect.size.width = rect.size.width + CGFloat(thickness.x)
        edgeRect.size.height = CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Right edge.
        edgeRect.origin.x = rect.origin.x + rect.size.width
        edgeRect.origin.y = rect.origin.y
        edgeRect.size.width = CGFloat(thickness.x)
        edgeRect.size.height = rect.size.height + CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Bottom edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y - CGFloat(thickness.y)
        edgeRect.size.width = rect.size.width + 2 * CGFloat(thickness.x)
        edgeRect.size.height = CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
    }

    func drawRects(renderEncoder: MTLRenderCommandEncoder, color: simd_float4,
                   rect: CGRect, strongDecision: Bool, thickness: simd_float2) {
        if strongDecision {
            drawStrongDecionRect(renderEncoder: renderEncoder, color: color, rect: rect, thickness: thickness)
            return
        }

        // Weak-decision rectangle.
        var edgeRect = CGRect.zero
        // Left edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y
        edgeRect.size.width = CGFloat(thickness.x)
        edgeRect.size.height = (rect.size.height / 3) + CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        edgeRect.origin.y += (rect.size.height * 2 / 3)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Top edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y + rect.size.height
        edgeRect.size.width = (rect.size.width / 3) + CGFloat(thickness.x)
        edgeRect.size.height = CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        edgeRect.origin.x += (rect.size.width * 2 / 3)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Right edge.
        edgeRect.origin.x = rect.origin.x + rect.size.width
        edgeRect.origin.y = rect.origin.y
        edgeRect.size.width = CGFloat(thickness.x)
        edgeRect.size.height = rect.size.height / 3 + CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        edgeRect.origin.y += (rect.size.height * 2 / 3)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        // Bottom edge.
        edgeRect.origin.x = rect.origin.x - CGFloat(thickness.x)
        edgeRect.origin.y = rect.origin.y - CGFloat(thickness.y)
        edgeRect.size.width = (rect.size.width / 3) + 2 * CGFloat(thickness.x)
        edgeRect.size.height = CGFloat(thickness.y)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
        edgeRect.origin.x += (rect.size.width * 2 / 3)
        drawRect(renderEncoder: renderEncoder, color: color, edgeRect: edgeRect)
    }

    func drawRect(renderEncoder: MTLRenderCommandEncoder, color: simd_float4, edgeRect: CGRect) {
        var vertices: [simd_float2] = []
        vertices.append(simd_make_float2(Float(edgeRect.origin.x), 1 - Float(edgeRect.origin.y)))
        vertices.append(simd_make_float2(Float(edgeRect.origin.x), 1
                                         - Float(edgeRect.origin.y + edgeRect.size.height)))
        vertices.append(simd_make_float2(Float(edgeRect.origin.x + edgeRect.size.width), 1
                                         - Float(edgeRect.origin.y)))
        vertices.append(simd_make_float2(Float(edgeRect.origin.x + edgeRect.size.width), 1
                                         - Float(edgeRect.origin.y + edgeRect.size.height)))
        renderEncoder.setVertexBytes(&vertices, length: MemoryLayout.size(ofValue: vertices[0]) * 4, index: 0)
        var colorVal = color
        renderEncoder.setVertexBytes(&colorVal, length: MemoryLayout.size(ofValue: colorVal), index: 1)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}
