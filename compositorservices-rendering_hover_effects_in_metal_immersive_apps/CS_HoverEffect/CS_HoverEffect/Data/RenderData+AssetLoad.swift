/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `RenderData` that contains functions related to asset loading.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit

import os.log

extension RenderData {
    // MARK: - Loading Assets

    /// An asynchronous task that loads the assets.
    func loadAssets() async {
        await withTaskGroup { group in
            group.addTask {
                await self.load(asset: self.asset)
            }
            group.addTask {
                await self.loadSkybox()
            }
            group.addTask {
                await self.loadSkyboxShader()
            }
        }
    }
    
    /// Performs skybox loading.
    private func loadSkybox() async {
        let url = Bundle.main.url(
            forResource: "Scene/Nebula_VerticalCubeMap",
            withExtension: "exr"
        )!
        skybox = try! await textureLoader.newTexture(
            URL: url,
            options: [
                .cubeLayout: MTKTextureLoader.CubeLayout.vertical,
                .allocateMipmaps: true,
                .generateMipmaps: true
            ]
        )
    }
    
    /// Performs skybox shader loading.
    private func loadSkyboxShader() async {
        let library = device.makeDefaultLibrary()!
        let pDesc = MTLRenderPipelineDescriptor()
        pDesc.colorAttachments[0].pixelFormat = renderer.configuration.colorFormat
        if #available(visionOS 26.0, *), appModel.withHover {
            pDesc.colorAttachments[1].pixelFormat = renderer.configuration.trackingAreasFormat
        }
        pDesc.depthAttachmentPixelFormat = renderer.configuration.depthFormat

        let constants = MTLFunctionConstantValues()
        var texture = false
        constants.setConstantValue(&texture, type: .bool, index: Int(FunctionConstantTexture.rawValue))
        var normals = false
        constants.setConstantValue(&normals, type: .bool, index: Int(FunctionConstantNormals.rawValue))
        pDesc.vertexFunction = try! await library.makeFunction(
            name: "vertexShader",
            constantValues: constants
        )
        pDesc.fragmentFunction = try! await library.makeFunction(
            name: "skyboxFragmentShader",
            constantValues: constants
        )
        let vDesc = MTLVertexDescriptor()
        vDesc.attributes[0].format = .float3
        vDesc.attributes[0].bufferIndex = 0
        vDesc.attributes[0].offset = 0
        vDesc.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        pDesc.vertexDescriptor = vDesc
        pDesc.maxVertexAmplificationCount = renderer.properties.viewCount
        if appModel.useMSAA {
            pDesc.rasterSampleCount = 4
        }
        let pState = try! await device.makeRenderPipelineState(descriptor: pDesc)
        skyboxPipeline = pState
    }
    
    /// Performs the asynchronous loading of the specified asset.
    /// - Parameter asset: The asset to load asynchronously.
    private func load(asset: MDLAsset) async {
        var objects: [MDLObject] = []
        for index in 0..<asset.count { objects.append(asset.object(at: index)) }
        while let object = objects.popLast() {
            objects.append(contentsOf: object.children.objects)

            if let mesh = object as? MDLMesh {
                let submeshes = mesh.submeshes?.map { $0 as? MDLSubmesh }
                guard let submeshes = submeshes else {
                    logger.log(level: .error, "Submeshes was unexpectedly nil.")
                    continue
                }
                let materials: [DrawCallMaterial] = submeshes.map { submesh in
                    guard let color = submesh?.material?.propertyNamed("emissiveColor")
                    else { return .init() }
                    let texture: MTLTexture? = {
                        guard let url = color.urlValue else { return nil }
                        if let texture = textures[url] {
                            return texture
                        }
                        let texture = try! textureLoader.newTexture(URL: url, options: [
                            .allocateMipmaps: true,
                            .generateMipmaps: true
                        ])
                        textures[url] = texture
                        return texture
                    }()
                    return DrawCallMaterial(
                        texture: texture,
                        color: color.float4Value
                    )
                }
                await scene.add(DrawCall(
                    transformWhole: rootTransform * MDLTransform.globalTransform(with: mesh, atTime: 0),
                    transformExploded: rootTransform * MDLTransform.globalTransform(with: mesh, atTime: 3),
                    mesh: try! .init(mesh: mesh, device: device),
                    boundingBox: .init(), //mesh.boundingBox,
                    materials: materials
                ))
            }
        }
    }
}
