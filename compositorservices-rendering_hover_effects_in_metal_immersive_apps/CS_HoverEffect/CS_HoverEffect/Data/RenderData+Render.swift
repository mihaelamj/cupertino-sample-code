/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `RenderData` that contains render-related functions.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit
import Spatial

import os.log

extension RenderData {
    
    func renderLoop() async {
        while renderer.state != .invalidated {
            guard let frame = renderer.queryNextFrame() else { continue }
            frame.startUpdate()
            frame.endUpdate()

            guard let timing = frame.predictTiming() else { continue }
            do {
                try await LayerRenderer.Clock().sleep(until: timing.optimalInputTime, tolerance: nil)
            } catch {
                logger.log(level: .error, "Unable to sleep frame loop: \(error)")
            }
            frame.startSubmission()

            let drawables = {
                #if os(visionOS)
                if #available(visionOS 26.0, *) {
                    return frame.queryDrawables()
                } else {
                    return frame.queryDrawable().map { [$0] } ?? []
                }
                #else
                return frame.queryDrawables()
                #endif
            }()
            
            if drawables.isEmpty { break }
            buffer = queue.makeCommandBuffer()!
            for pair in drawables.enumerated() {
                let drawable = pair.element
                let offset = pair.offset
                await handleDrawable(drawable, offset)
            }
           
            buffer?.commit()
            frame.endSubmission()

            await animate()
        }
        logger.log(level: .info, "Renderer invalidated")
        appModel.isImmersiveSpaceOpen = false
    }
    
    /// Performs the rendering of the scene.
    /// - Parameters:
    ///   - drawable: The drawable to render to.
    ///   - offset: The index of the drawable in the array that `queryDrawables()` returns.
    private func handleDrawable(_ drawable: LayerRenderer.Drawable, _ offset: Int) async {
        let drawCalls = await scene.drawCalls
        let time = LayerRenderer.Clock.Instant.epoch.duration(to: drawable.frameTiming.presentationTime).timeInterval
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: time)
        drawable.deviceAnchor = deviceAnchor
        
        await setUpMSAA(drawable: drawable,
                        offset: offset)

        let renderPassDescriptor = setupRenderPassDescriptor(drawable, offset: offset)
        guard let buffer = self.buffer else {
            logger.log(level: .error, "Command buffer is nil.")
            return
        }
        let encoder = buffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        let viewports = drawable.views.map { $0.textureMap.viewport }
        encoder.setViewports(viewports)

        if drawable.views.count > 1 {
            var viewMappings = (0..<drawable.views.count).map {
                MTLVertexAmplificationViewMapping(viewportArrayIndexOffset: UInt32($0),
                                                  renderTargetArrayIndexOffset: UInt32($0))
            }
            encoder.setVertexAmplificationCount(viewports.count, viewMappings: &viewMappings)
        }

        if let depthState = depthState {
            encoder.setDepthStencilState(depthState)
        } else {
            logger.log(level: .debug, "Depth State not set up.")
        }

        renderSkybox(encoder: encoder, drawable: drawable)

        for pair in drawCalls.enumerated() {
            let drawCall = pair.element
            let id = pair.offset + 1
            handleDrawCall(encoder: encoder,
                           drawable: drawable,
                           drawCall: drawCall,
                           id: id)
        }

        if #available(visionOS 26.0, *), appModel.withHover {
            if let pipeline {
                encoder.setRenderPipelineState(pipeline.indexResolveState)
                encoder.setTileTexture(drawable.trackingAreasTextures[0], index: 0)
                encoder.dispatchThreadsPerTile(MTLSize(width: 32, height: 16, depth: 1))
            }
        }

        encoder.endEncoding()
        drawable.encodePresent(commandBuffer: buffer)
    }
    
    /// Returns a new render pass descriptor for the specified drawable.
    /// - Parameters:
    ///   - drawable: The drawable to create a render pass descriptor for.
    ///   - offset: The index of the drawable in the `LayerRenderer.Drawable` array.
    private func setupRenderPassDescriptor(_ drawable: LayerRenderer.Drawable, offset: Int) -> MTLRenderPassDescriptor {
        assert(drawable.colorTextures.count == 1)
        let renderPassDescriptor = MTLRenderPassDescriptor()
        if appModel.useMSAA {
            renderPassDescriptor.colorAttachments[0].texture = colorTextureCache.perDrawable[offset]
            renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.colorTextures[0]
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        } else {
            renderPassDescriptor.colorAttachments[0].texture = drawable.colorTextures[0]
            renderPassDescriptor.colorAttachments[0].storeAction = .store
        }
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
        if #available(visionOS 26.0, *), appModel.withHover {
            if appModel.useMSAA {
                renderPassDescriptor.colorAttachments[1].texture = indexTextureCache.perDrawable[offset]
                renderPassDescriptor.colorAttachments[1].storeAction = .dontCare
            } else {
                renderPassDescriptor.colorAttachments[1].texture = drawable.trackingAreasTextures[0]
                renderPassDescriptor.colorAttachments[1].storeAction = .store
            }
            renderPassDescriptor.colorAttachments[1].loadAction = .clear
        }
        if appModel.useMSAA {
            renderPassDescriptor.depthAttachment.storeAction = .multisampleResolve
            renderPassDescriptor.depthAttachment.resolveTexture = drawable.depthTextures[0]
            renderPassDescriptor.depthAttachment.texture = depthTextureCache.perDrawable[offset]
        } else {
            renderPassDescriptor.depthAttachment.storeAction = .store
            renderPassDescriptor.depthAttachment.texture = drawable.depthTextures[0]
        }
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1E-4

        renderPassDescriptor.rasterizationRateMap = drawable.rasterizationRateMaps.first
        if renderer.configuration.layout == .layered {
            renderPassDescriptor.renderTargetArrayLength = drawable.views.count
        }
        return renderPassDescriptor
    }

    /// Renders the skybox.
    /// - Parameters:
    ///   - encoder: The render command encoder to use.
    ///   - drawable: The drawable to render to.
    private func renderSkybox(encoder: (any MTLRenderCommandEncoder),
                              drawable: LayerRenderer.Drawable) {
        guard let skybox, let skyboxPipeline else { return }

        // Cube (8 vertices).
        let positions: [SIMD3<Float>] = [
            [-1, -1, +1],
            [-1, +1, +1],
            [-1, -1, -1],
            [-1, +1, -1],
            [+1, -1, +1],
            [+1, +1, +1],
            [+1, -1, -1],
            [+1, +1, -1]
        ].map { $0 }

        let indices: [Int] = [
            2, 3, 1,
            4, 7, 3,
            8, 5, 7,
            6, 1, 5,
            7, 1, 3,
            4, 6, 8,
            2, 4, 3,
            4, 8, 7,
            8, 6, 5,
            6, 2, 1,
            7, 5, 1,
            4, 2, 6
        ].map { $0 - 1 } // OBJ starts at 1

        let cornerPositions: [SIMD3<Float>] = indices.map { index in
            100 * SIMD3<Float>(positions[index])
        }

        cornerPositions.withUnsafeBytes { ptr in
            encoder.setVertexBytes(ptr.baseAddress!, length: MemoryLayout<SIMD3<Float>>.size * cornerPositions.count, index: 0)
        }

        var uniforms = UniformsArray()

        uniforms.debugFactor = appModel.debugFactor

        let transform = simd_float4x4(diagonal: SIMD4<Float>(repeating: 1.0))

        uniforms.uniforms.0 = getUniforms(drawable, transform: transform,
                                          withTranslation: false, forViewIndex: 0)
        if drawable.views.count > 1 {
            uniforms.uniforms.1 = getUniforms(drawable, transform: transform,
                                              withTranslation: false, forViewIndex: 1)
        }

        encoder.setVertexBytes(&uniforms, length: MemoryLayout<UniformsArray>.size, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<UniformsArray>.size, index: 1)

        encoder.setFragmentTexture(skybox, index: 0)
        encoder.setRenderPipelineState(skyboxPipeline)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cornerPositions.count)
    }
    
    /// Performs the actual drawing of a single draw call.
    /// - Parameters:
    ///   - encoder: The render command encoder to use.
    ///   - drawable: The drawable to render to.
    ///   - drawCall: The draw call to perform.
    ///   - id: The index of the draw call to perform.
    private func handleDrawCall(encoder: (any MTLRenderCommandEncoder),
                                drawable: LayerRenderer.Drawable,
                                drawCall: DrawCall,
                                id: Int) {
        let pose1 = AffineTransform3D(truncating: drawCall.transformWhole)
        let pose2 = AffineTransform3D(truncating: drawCall.transformExploded)
        let blend = 1 - Double(drawCall.animationState.transformBlend)
        let scale = blend * pose1.scale + (1 - blend) * pose2.scale
        let rotation = simd_slerp(pose1.rotation!.quaternion, pose2.rotation!.quaternion, 1 - blend)
        let translation = blend * pose1.translation + (1 - blend) * pose2.translation
        let pose = AffineTransform3D(
            scale: scale,
            rotation: Rotation3D(rotation),
            translation: translation
        )
        let transform = simd_float4x4(pose)
        let mesh = drawCall.mesh

        var uniforms = UniformsArray()

        uniforms.debugFactor = appModel.debugFactor

        uniforms.uniforms.0 = getUniforms(drawable, transform: transform, forViewIndex: 0)
        if drawable.views.count > 1 {
            uniforms.uniforms.1 = getUniforms(drawable, transform: transform, forViewIndex: 1)
        }

        if #available(visionOS 26.0, *), drawCall.animationState.hasHover {
            if appModel.withHover {
                let trackingArea = drawable.addTrackingArea(identifier: .init(UInt64(id)))
                trackingArea.addHoverEffect(.automatic)
                uniforms.hoverIndex = trackingArea.renderValue.rawValue
            } else {
                uniforms.hoverIndex = UInt16(id)
            }
        }

        encoder.setVertexBytes(&uniforms, length: MemoryLayout<UniformsArray>.size, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<UniformsArray>.size, index: 1)

        for vertexBuffer in mesh.vertexBuffers {
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
        }
        for index in 0..<mesh.submeshes.count {
            let submesh = mesh.submeshes[index]
            let material = drawCall.materials[index]
            handleSubMesh(encoder: encoder,
                          submesh: submesh,
                          material: material)
        }
    }
    
    /// Returns the uniform data needed for rendering.
    /// - Parameters:
    ///   - drawable: The drawable to use for retrieving the view matrix.
    ///   - transform: The current model transform.
    ///   - withTranslation: The flag that indicates whether to include the translation.
    ///   - viewIndex: The index of the view to use for computing the uniform data.
    private func getUniforms(_ drawable: LayerRenderer.Drawable,
                             transform: simd_float4x4,
                             withTranslation: Bool = true,
                             forViewIndex viewIndex: Int) -> Uniforms {
        let view = drawable.views[viewIndex]
        let simdDeviceAnchor = drawable.deviceAnchor?.originFromAnchorTransform ?? matrix_identity_float4x4
        var viewMatrix = (simdDeviceAnchor * view.transform).inverse
        if !withTranslation {
            viewMatrix.columns.3.x = 0
            viewMatrix.columns.3.y = 0
            viewMatrix.columns.3.z = 0
        }
        let projection = drawable.computeProjection(viewIndex: viewIndex)

        return Uniforms(
            projectionMatrix: projection,
            modelMatrix: transform,
            modelViewMatrix: viewMatrix * transform,
            viewWorldPosition: simd_inverse(viewMatrix).columns.3.xyz,
            normalMatrix: simd_transpose(simd_inverse(transform)),
            pmMatrix: projection * viewMatrix * transform
        )
    }
    
    /// Performs drawing of a single submesh.
    /// - Parameters:
    ///   - encoder: The render command encoder to use for drawing.
    ///   - submesh: The submesh to draw.
    ///   - material: The material properties for the submesh.
    private func handleSubMesh(encoder: (any MTLRenderCommandEncoder),
                               submesh: MTKSubmesh,
                               material: DrawCallMaterial) {
        encoder.setRenderPipelineState(pStates[ShaderConstants(
            color: material.color != nil,
            texture: material.texture != nil,
            debugColors: appModel.debugFactor > 0
        )]!)

        encoder.setFragmentTexture(material.texture, index: 0)
        encoder.setFragmentTexture(skybox, index: 1)
        if var color = material.color {
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
        }
        encoder.drawIndexedPrimitives(
            type: submesh.primitiveType,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: submesh.indexBuffer.offset
        )
    }
}
