/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Renderer class which performs Metal setup and per frame rendering for a
 single pass deferred renderer used for iOS & tvOS devices
*/

import MetalKit

class SinglePassDeferredRenderer: Renderer {

    init(device: MTLDevice,
         scene: Scene,
         renderDestination: RenderDestination,
         didBeginFrame: @escaping () -> Void) {

        super.init(device: device,
                   scene: scene,
                   renderDestination: renderDestination,
                   singlePass: true,
                   didBeginFrame: didBeginFrame)
    }

    let gBufferAndLightingPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // We can't (and don't need to) store these color attachments in single pass deferred rendering
        // because they are memoryless and are only needed temporarily during the rendering process.
        descriptor.colorAttachments[Int(AAPLRenderTargetAlbedo.rawValue)].storeAction = .dontCare
        descriptor.colorAttachments[Int(AAPLRenderTargetNormal.rawValue)].storeAction = .dontCare
        descriptor.colorAttachments[Int(AAPLRenderTargetDepth.rawValue)].storeAction = .dontCare
        return descriptor
    }()
}

extension SinglePassDeferredRenderer {
    
    /// MTKViewDelegate Callback: Respond to device orientation change or other view size change
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        guard let device = view.device else {
            fatalError("MTKView does not have a MTLDevice.")
        }
        
        var storageMode = MTLStorageMode.private
          
        if #available(macOS 11, *) {
            storageMode = .memoryless
        }
        
        drawableSizeWillChange?(device, size, storageMode)
        // Re-set GBuffer textures in the view render pass descriptor after they have been reallocated by a resize
        setGBufferTextures(gBufferAndLightingPassDescriptor)
        
        // Draw once even though the view is paused to make sure the scene does not appear stretched.
        if view.isPaused {
            view.draw()
        }
    }
    
    /// MTKViewDelegate callback: Called whenever the view needs to render
    override func draw(in view: MTKView) {
        var commandBuffer = beginFrame()
        commandBuffer.label = "Shadow Commands"
        
        // MARK: - Shadow Map Pass
        encodeShadowMapPass(into: commandBuffer)
        
        // Commit commands so that Metal can begin working on non-drawable dependant work without
        // waiting for a drawable to become avaliable
        commandBuffer.commit()
        
        commandBuffer = beginDrawableCommands()
        commandBuffer.label = "GBuffer & Lighting Commands"
        
        // MARK: - GBuffer & Lighting Pass
        // The final pass can only render if a drawable is available, otherwise it needs to skip
        // rendering this frame.
        if let drawableTexture = view.currentDrawable?.texture {
            gBufferAndLightingPassDescriptor.colorAttachments[Int(AAPLRenderTargetLighting.rawValue)].texture = drawableTexture
            gBufferAndLightingPassDescriptor.depthAttachment.texture = view.depthStencilTexture
            gBufferAndLightingPassDescriptor.stencilAttachment.texture = view.depthStencilTexture
            
            encodePass(into: commandBuffer, using: gBufferAndLightingPassDescriptor, label: "GBuffer & Lighting Pass") { renderEncoder in
                
                encodeGBufferStage(using: renderEncoder)
                encodeDirectionalLightingStage(using: renderEncoder)
                encodeLightMaskStage(using: renderEncoder)
                encodePointLightStage(using: renderEncoder)
                encodeSkyboxStage(using: renderEncoder)
                encodeFairyBillboardStage(using: renderEncoder)
            }
        }
        
        endFrame(commandBuffer)
    }
    
}
