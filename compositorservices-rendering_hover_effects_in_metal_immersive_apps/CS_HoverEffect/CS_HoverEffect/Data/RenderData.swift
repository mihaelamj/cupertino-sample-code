/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app class.
*/

import SwiftUI
import RealityKit

import CompositorServices

import ModelIO
import ARKit
@preconcurrency import MetalKit
import Spatial

import os.log

/// A class that encapsulates the rendering state for the app.
actor RenderData {
    
    /// The Metal device for the app.
    var device: MTLDevice
    
    /// The command queue for the app.
    var queue: MTLCommandQueue

    /// The ARKit session.
    let session: ARKitSession?

    /// The world-tracking provider.
    let worldTracking = WorldTrackingProvider()
    
    /// The vertex descriptor for the scene geometry.
    let mdlVD: MDLVertexDescriptor
    
    /// The URL of the scene asset.
    let assetURL: URL
    
    /// The scene asset.
    let asset: MDLAsset
    
    /// The root transform for the scene.
    let rootTransform = Transform(scale: [2, 2, 2],
                                  translation: [0, -2.0, -5.0]).matrix
    /// The texture loader.
    let textureLoader: MTKTextureLoader
    
    /// The scene to render.
    let scene = Scene()
    
    /// The cache for textures.
    var textures = [URL: MTLTexture]()
    
    /// The drawables for the current frame.
    var drawables = [LayerRenderer.Drawable]()
    
    /// The cache for color textures.
    var colorTextureCache = TextureCache()
    
    /// The cache for index textures.
    var indexTextureCache = TextureCache()
    
    /// The cache for depth textures.
    var depthTextureCache = TextureCache()
    
    /// The command buffer to use for rendering.
    var buffer: (any MTLCommandBuffer)?
    
    /// The depth state to use for rendering.
    var depthState: (any MTLDepthStencilState)?
    
    /// The pipeline states for different shader constants.
    var pStates = [ShaderConstants: MTLRenderPipelineState]()
    
    /// The pipeline state for handling object indices with MSAA.
    var pipeline: TileResolvePipeline?
    
    /// The skybox texture.
    var skybox: MTLTexture!
    
    /// The pipeline state for rendering the skybox.
    var skyboxPipeline: MTLRenderPipelineState!

    weak var _appModel: AppModel?
    
    /// The Compositor Services layer renderer.
    let renderer: LayerRenderer
    
    /// The Metal device.
    var appModel: AppModel { _appModel ?? AppModel() }
    
    /// The time of rendering the last frame.
    var lastRenderTime: TimeInterval?

    /// Creates a `RenderData` instance.
    /// - Parameters:
    ///   - theRenderer: The layer renderer.
    ///   - theAppModel: The app model.
    init(
        layerRenderer theRenderer: LayerRenderer,
        context: CompositorLayerContext,
        theAppModel: AppModel
    ) {
        #if os(macOS)
        session = context.remoteDeviceIdentifier.map { ARKitSession(device: $0) }
        #else
        session = ARKitSession()
        #endif

        let device = theRenderer.device
        self.device = device
        queue = device.makeCommandQueue()!
        let mdlVD = MDLVertexDescriptor()
        self.mdlVD = mdlVD
        mdlVD.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                 format: .float3, offset: 0, bufferIndex: 0)
        mdlVD.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                 format: .float2,
                                                 offset: MemoryLayout<SIMD3<Float>>.stride,
                                                 bufferIndex: 0)
        mdlVD.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                 format: .float3,
                                                 offset: MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride,
                                                 bufferIndex: 0)
        mdlVD.layouts[0] = MDLVertexBufferLayout(stride: 2 * MemoryLayout<SIMD3<Float>>.stride +
                                                 MemoryLayout<SIMD2<Float>>.stride)
        assetURL = theAppModel.modelURL
        asset = MDLAsset(
            url: assetURL,
            vertexDescriptor: mdlVD,
            bufferAllocator: MTKMeshBufferAllocator(device: device)
        )
        textureLoader = MTKTextureLoader(device: device)
        _appModel = theAppModel
        renderer = theRenderer
    }
    
    // MARK: - Mutators and Accessors
    
    /// Performs an update to the render pipeline state dictionary.
    /// - Parameters:
    ///   - key: The key to use for storing the pipeline state.
    ///   - value: The new render pipeline state.
    func updatePipelineState(key: ShaderConstants, value: MTLRenderPipelineState) async {
        pStates[key] = value
    }
    
    /// Returns the render pipeline state dictionary.
    func getDepthState() -> (any MTLDepthStencilState)? {
        depthState
    }
    
    /// Returns the render pipeline state dictionary.
    /// - Parameter color: The material property with the texture to return.
    func getRenderTexture(color: MDLMaterialProperty) -> MTLTexture? {
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
    }
    
    // MARK: - Initial Setup
    
    /// Performs initial setup of the tile resolve pipeline state object.
    func setUpTileResolvePipeline() async {
        if appModel.withHover && appModel.useMSAA {
            pipeline = TileResolvePipeline(device: device,
                                           configuration: renderer.configuration)
        } else {
            pipeline = nil
        }
    }
    
    private func setUpShaderVariantsArray() async -> [ShaderConstants] {
        var shaderVariants: [ShaderConstants] = []
        for color in [true, false] {
            for texture in [true, false] {
                for debugColors in [true, false] {
                    shaderVariants.append(ShaderConstants(
                        color: color,
                        texture: texture,
                        debugColors: debugColors
                    ))
                }
            }
        }
        return shaderVariants
    }
    
    /// Performs initial setup of the shader pipeline state object.
    func setUpShaderPipeline () async {

        let compilationStart = Date()
        await withTaskGroup(of: Void.self) { group in
            let shaderVariants: [ShaderConstants] = await setUpShaderVariantsArray()

            for shaderConstants in shaderVariants {
                group.addTask { [self] in
                    let vDesc = MTKMetalVertexDescriptorFromModelIO(mdlVD)
                    let library = await device.makeDefaultLibrary()!
                    let pDesc = MTLRenderPipelineDescriptor()
                    pDesc.colorAttachments[0].pixelFormat = renderer.configuration.colorFormat
                    if #available(visionOS 26.0, *), await appModel.withHover {
                        pDesc.colorAttachments[1].pixelFormat = renderer.configuration.trackingAreasFormat
                    }
                    pDesc.depthAttachmentPixelFormat = renderer.configuration.depthFormat
                    let constants = MTLFunctionConstantValues()
                    var color = shaderConstants.color
                    constants.setConstantValue(&color, type: .bool, index: Int(FunctionConstantColor.rawValue))
                    var texture = shaderConstants.texture
                    constants.setConstantValue(&texture, type: .bool, index: Int(FunctionConstantTexture.rawValue))
                    var normals = shaderConstants.normals
                    constants.setConstantValue(&normals, type: .bool, index: Int(FunctionConstantNormals.rawValue))
                    var debugColors = shaderConstants.debugColors
                    constants.setConstantValue(&debugColors, type: .bool, index: Int(FunctionConstantDebugColors.rawValue))
                    pDesc.vertexFunction = try! await library.makeFunction(
                        name: "vertexShader",
                        constantValues: constants
                    )
                    pDesc.fragmentFunction = try! await library.makeFunction(
                        name: "fragmentShader",
                        constantValues: constants
                    )
                    pDesc.vertexDescriptor = vDesc
                    pDesc.maxVertexAmplificationCount = renderer.properties.viewCount
                    if await appModel.useMSAA {
                        pDesc.rasterSampleCount = 4
                    }
                    let pState = try! await device.makeRenderPipelineState(descriptor: pDesc)
                    await updatePipelineState(key: shaderConstants, value: pState)
                }
            }
        }
        print("Compiled shaders in \(Int(Date().timeIntervalSince(compilationStart) * 1000)) ms")
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.greater
        depthStateDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
    }
    
    /// Performs per-frame setup for the depth stencil buffer.
    func setUpDepthState() async {
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.greater
        depthStateDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
    }
    
    /// Performs setup for world tracking.
    func setUpWorldTracking() async {
        if WorldTrackingProvider.isSupported {
            try! await session?.run([worldTracking])
        }
    }
    
    /// Performs setup for the depth stencil.
    /// - Parameter encoder: The render command encoder.
    func setDepthStencilState(for encoder: MTLRenderCommandEncoder) async {
        encoder.setDepthStencilState(depthState)
    }
    
    /// Performs setup for MSAA.
    ///
    /// If using MSAA and the color, depth, or tracking caches are nil, it creates a "memoryless" copy
    /// of the color, depth, and tracking buffers from the drawable and puts it in the appropriate cache.
    /// - Parameters:
    ///   - drawable: The drawable.
    ///   - offset: The drawable index.
    func setUpMSAA(drawable: LayerRenderer.Drawable,
                   offset: Int) async {
        
        if appModel.useMSAA {
            if colorTextureCache.perDrawable[offset] == nil {
                colorTextureCache.perDrawable[offset] = memorylessTexture(from: drawable.colorTextures[0])
            }
            
            if #available(visionOS 26.0, *), appModel.withHover {
                if indexTextureCache.perDrawable[offset] == nil {
                    indexTextureCache.perDrawable[offset] = memorylessTexture(from: drawable.trackingAreasTextures[0])
                }
            }
            
            if depthTextureCache.perDrawable[offset] == nil {
                depthTextureCache.perDrawable[offset] = memorylessTexture(from: drawable.depthTextures[0])
            }
        }
    }
    
    // MARK: - Utilities
    
    /// Returns a "memoryless" texture from the given input texture.
    ///
    /// A "memoryless" texture is a temporary copy of an texture that the system stores in
    /// tile memory temporarily. It's only available within the current single render pass.
    /// - Parameter texture: The input texture.
    func memorylessTexture(from texture: MTLTexture) -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat,
                                                                  width: texture.width,
                                                                  height: texture.height,
                                                                  mipmapped: false)
        descriptor.usage = .renderTarget
        descriptor.textureType = .type2DMultisampleArray
        descriptor.sampleCount = 4
        descriptor.storageMode = .memoryless
        descriptor.arrayLength = texture.arrayLength
        return texture.device.makeTexture(descriptor: descriptor)!
    }
}
