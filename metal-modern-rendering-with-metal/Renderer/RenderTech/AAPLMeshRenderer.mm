/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of class which renders meshes
*/

#import "AAPLMeshRenderer.h"

#import "AAPLCulling.h"
#import "AAPLMesh.h"
#import "AAPLTextureManager.h"

#import "AAPLUtilities.h"
#import "AAPLMeshTypes.h"
#import "AAPLShaderTypes.h"
#import "AAPLCommon.h"

@implementation AAPLMeshRenderer
{
    // Device from initialization.
    id<MTLDevice> _device;

    AAPLTextureManager*         _textureManager;

    // - GBuffer
    id <MTLRenderPipelineState> _gBufferOpaque;
    id <MTLRenderPipelineState> _gBufferAlphaMask;
    id <MTLRenderPipelineState> _gBufferDebug;

    //  - Depth Only
    id <MTLRenderPipelineState> _depthOnlyOpaque;
    id <MTLRenderPipelineState> _depthOnlyAlphaMask;

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    id <MTLRenderPipelineState> _depthOnlyAmplifiedOpaque;
    id <MTLRenderPipelineState> _depthOnlyAmplifiedAlphaMask;
#endif

#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
    id <MTLRenderPipelineState> _depthOnlyTileOpaque;
    id <MTLRenderPipelineState> _depthOnlyTileAlphaMask;
#endif

    //  - Forward
    id <MTLRenderPipelineState> _forwardOpaque;
    id <MTLRenderPipelineState> _forwardAlphaMask;
    id <MTLRenderPipelineState> _forwardTransparent;
    id <MTLRenderPipelineState> _forwardTransparentLightCluster;

    id <MTLRenderPipelineState> _forwardOpaqueDebug;
    id <MTLRenderPipelineState> _forwardAlphaMaskDebug;
    id <MTLRenderPipelineState> _forwardTransparentDebug;
    id <MTLRenderPipelineState> _forwardTransparentLightClusterDebug;

    size_t _materialSize;
    size_t _alignedMaterialSize;

    uint _lightCullingTileSize;
    uint _lightClusteringTileSize;
}

-(nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                       textureManager:(nonnull AAPLTextureManager*)textureManager
                         materialSize:(size_t)materialSize
                  alignedMaterialSize:(size_t)alignedMaterialSize
                              library:(nonnull id<MTLLibrary>)library
                  GBufferPixelFormats:(nonnull const MTLPixelFormat*)GBufferPixelFormats
                  lightingPixelFormat:(MTLPixelFormat)lightingPixelFormat
                   depthStencilFormat:(MTLPixelFormat)depthStencilFormat
                          sampleCount:(NSUInteger)sampleCount
                 useRasterizationRate:(BOOL)useRasterizationRate
           singlePassDeferredLighting:(BOOL)singlePassDeferredLighting
                 lightCullingTileSize:(uint)lightCullingTileSize
              lightClusteringTileSize:(uint)lightClusteringTileSize
           useSinglePassCSMGeneration:(BOOL)useSinglePassCSMGeneration
       genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification
{
    self = [super init];
    if (self)
    {
        _device         = device;
        _textureManager = textureManager;

        _materialSize            = materialSize;
        _alignedMaterialSize     = alignedMaterialSize;

        _lightCullingTileSize    = lightCullingTileSize;
        _lightClusteringTileSize = lightClusteringTileSize;

        [self rebuildPipelinesWithLibrary:library
                      GBufferPixelFormats:GBufferPixelFormats
                      lightingPixelFormat:lightingPixelFormat
                       depthStencilFormat:depthStencilFormat
                              sampleCount:sampleCount
                     useRasterizationRate:useRasterizationRate
               singlePassDeferredLighting:singlePassDeferredLighting
               useSinglePassCSMGeneration:useSinglePassCSMGeneration
           genCSMUsingVertexAmplification:genCSMUsingVertexAmplification];
    }
    return self;
}

-(void)rebuildPipelinesWithLibrary:(nonnull id<MTLLibrary>)library
               GBufferPixelFormats:(nonnull const MTLPixelFormat*)GBufferPixelFormats
               lightingPixelFormat:(MTLPixelFormat)lightingPixelFormat
                depthStencilFormat:(MTLPixelFormat)depthStencilFormat
                       sampleCount:(NSUInteger)sampleCount
              useRasterizationRate:(BOOL)useRasterizationRate
        singlePassDeferredLighting:(BOOL)singlePassDeferredLighting
        useSinglePassCSMGeneration:(BOOL)useSinglePassCSMGeneration
    genCSMUsingVertexAmplification:(BOOL)genCSMUsingVertexAmplification
{
    static const bool TRUE_VALUE  = true;
    static const bool FALSE_VALUE = false;

    NSError* error;

    //Both Apple Silicon and iPhone will respond with true
    id <MTLFunction> nilFragmentFunction = [_device supportsFamily:MTLGPUFamilyApple4] ? [library newFunctionWithName:@"dummyFragmentShader"] : nil;

    // ----------------------------------
    // Create vertex descriptors
    // ----------------------------------

    MTLVertexDescriptor *vd = [[MTLVertexDescriptor alloc] init];

    vd.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    vd.attributes[AAPLVertexAttributePosition].offset = 0;
    vd.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexVertexMeshPositions;

    vd.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
    vd.attributes[AAPLVertexAttributeNormal].offset = 0;
    vd.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexVertexMeshNormals;

    vd.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatFloat3;
    vd.attributes[AAPLVertexAttributeTangent].offset = 0;
    vd.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexVertexMeshTangents;

    vd.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    vd.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    vd.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexVertexMeshGenerics;

    vd.layouts[AAPLBufferIndexVertexMeshPositions].stride = 12;
    vd.layouts[AAPLBufferIndexVertexMeshPositions].stepRate = 1;
    vd.layouts[AAPLBufferIndexVertexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    vd.layouts[AAPLBufferIndexVertexMeshNormals].stride = 12;
    vd.layouts[AAPLBufferIndexVertexMeshNormals].stepRate = 1;
    vd.layouts[AAPLBufferIndexVertexMeshNormals].stepFunction = MTLVertexStepFunctionPerVertex;

    vd.layouts[AAPLBufferIndexVertexMeshTangents].stride = 12;
    vd.layouts[AAPLBufferIndexVertexMeshTangents].stepRate = 1;
    vd.layouts[AAPLBufferIndexVertexMeshTangents].stepFunction = MTLVertexStepFunctionPerVertex;

    vd.layouts[AAPLBufferIndexVertexMeshGenerics].stride = 8;
    vd.layouts[AAPLBufferIndexVertexMeshGenerics].stepRate = 1;
    vd.layouts[AAPLBufferIndexVertexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    // Depth Only Vertex Descriptor

    MTLVertexDescriptor *depthOnlyVD = [[MTLVertexDescriptor alloc] init];

    depthOnlyVD.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    depthOnlyVD.attributes[AAPLVertexAttributePosition].offset = 0;
    depthOnlyVD.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexVertexMeshPositions;

    depthOnlyVD.layouts[AAPLBufferIndexVertexMeshPositions].stride = 12;
    depthOnlyVD.layouts[AAPLBufferIndexVertexMeshPositions].stepRate = 1;
    depthOnlyVD.layouts[AAPLBufferIndexVertexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Depth Only Alpha Mask Vertex Descriptor

    MTLVertexDescriptor *depthOnlyAlphaMaskVD = [depthOnlyVD copy];

    depthOnlyAlphaMaskVD.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    depthOnlyAlphaMaskVD.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    depthOnlyAlphaMaskVD.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexVertexMeshGenerics;

    depthOnlyAlphaMaskVD.layouts[AAPLBufferIndexVertexMeshGenerics].stride = 8;
    depthOnlyAlphaMaskVD.layouts[AAPLBufferIndexVertexMeshGenerics].stepRate = 1;
    depthOnlyAlphaMaskVD.layouts[AAPLBufferIndexVertexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    // ----------------------------------

    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];

    // ----------------------------------
    // Forward pipeline states
    // ----------------------------------
    {
        id <MTLFunction> fragmentFunctionOpaqueICB;
        id <MTLFunction> fragmentFunctionAlphaMaskICB;
        id <MTLFunction> fragmentFunctionTransparentICB;
        id <MTLFunction> fragmentFunctionLCTransparentICB;
        id <MTLFunction> fragmentFunctionOpaqueICBDebug;
        id <MTLFunction> fragmentFunctionAlphaMaskICBDebug;
        id <MTLFunction> fragmentFunctionTransparentICBDebug;
        id <MTLFunction> fragmentFunctionLCTransparentICBDebug;

        {
            MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

            [fc setConstantValue:&useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
            [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
            [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];

            fragmentFunctionOpaqueICB = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            fragmentFunctionAlphaMaskICB = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
            fragmentFunctionTransparentICB = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
            fragmentFunctionLCTransparentICB = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
            fragmentFunctionOpaqueICBDebug = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            fragmentFunctionAlphaMaskICBDebug = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
            fragmentFunctionTransparentICBDebug = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];

            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
            fragmentFunctionLCTransparentICBDebug = [library newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];
        }

        MTLRenderPipelineDescriptor *psd = [[MTLRenderPipelineDescriptor alloc] init];
        psd.sampleCount                     = sampleCount;
        psd.vertexFunction                  = vertexFunction;
        psd.vertexDescriptor                = vd;
        psd.colorAttachments[0].pixelFormat = lightingPixelFormat;
        psd.depthAttachmentPixelFormat      = depthStencilFormat;
        psd.supportIndirectCommandBuffers   = YES;

        psd.colorAttachments[0].blendingEnabled             = NO;

        psd.label               = @"MeshForwardPipelineState_Opaque_ICB";
        psd.fragmentFunction    = fragmentFunctionOpaqueICB;

        _forwardOpaque = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardOpaque, @"Failed to create mesh forward opaque ICB pipeline state: %@", error);

        psd.label               = @"MeshForwardPipelineState_AlphaMask_ICB";
        psd.fragmentFunction    = fragmentFunctionAlphaMaskICB;

        _forwardAlphaMask = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardAlphaMask, @"Failed to create mesh forward alpha mask ICB pipeline state: %@", error);

        psd.label                                                   = @"MeshForwardPipelineState_Transparent_ICB";
        psd.fragmentFunction                                = fragmentFunctionTransparentICB;
        psd.colorAttachments[0].rgbBlendOperation           = MTLBlendOperationAdd;
        psd.colorAttachments[0].alphaBlendOperation         = MTLBlendOperationAdd;
        psd.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactorOne;
        psd.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactorOne;
        psd.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactorOne;
        psd.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOne;
        psd.colorAttachments[0].blendingEnabled             = YES;

        _forwardTransparent = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardTransparent, @"Failed to create mesh forward transparent ICB pipeline state: %@", error);

        psd.label               = @"MeshForwardPipelineState_LightClusters_Transparent_ICB";
        psd.fragmentFunction    = fragmentFunctionLCTransparentICB;

        _forwardTransparentLightCluster = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardTransparentLightCluster, @"Failed to create mesh forward (with light clusters) transparent ICB pipeline state: %@", error);

        // ICB Debug pipelines

        psd.colorAttachments[0].blendingEnabled = NO;

        psd.label               = @"MeshForwardPipelineState_ICB_Debug";
        psd.fragmentFunction    = fragmentFunctionOpaqueICBDebug;

        _forwardOpaqueDebug = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardOpaqueDebug, @"Failed to create mesh forward opaque ICB pipeline state (debug): %@", error);

        psd.label               = @"MeshForwardPipelineState_AlphaMask_ICB_Debug";
        psd.fragmentFunction    = fragmentFunctionAlphaMaskICBDebug;

        _forwardAlphaMaskDebug = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardAlphaMaskDebug, @"Failed to create mesh forward alpha mask ICB pipeline state (debug): %@", error);

        psd.label                               = @"Mesh_Forward_Transparent_ICB_Debug_PipelineState";
        psd.fragmentFunction                    = fragmentFunctionTransparentICBDebug;
        psd.colorAttachments[0].blendingEnabled = NO;

        _forwardTransparentDebug = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardTransparentDebug, @"Failed to create mesh forward transparent ICB pipeline state (debug): %@", error);

        psd.label               = @"Mesh_Forward_LightClusters_Transparent_ICB_Debug_PipelineState";
        psd.fragmentFunction    = fragmentFunctionLCTransparentICBDebug;

        _forwardTransparentLightClusterDebug = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_forwardTransparentLightClusterDebug, @"Failed to create mesh forward (with light clusters) transparent ICB pipeline state (debug): %@", error);

        psd.colorAttachments[0].blendingEnabled = NO;
    }

    // ----------------------------------
    // Depth-only pipeline states
    // ----------------------------------
    {

        id <MTLFunction> depthOnlyVertexFunction = [library newFunctionWithName:@"vertexShaderDepthOnly"];

        MTLRenderPipelineDescriptor* depthOnlyDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        depthOnlyDescriptor.label                         = @"DepthOnlyPipelineState";
        depthOnlyDescriptor.sampleCount                   = 1;
        depthOnlyDescriptor.vertexFunction                = depthOnlyVertexFunction;
        depthOnlyDescriptor.fragmentFunction              = nilFragmentFunction;
        depthOnlyDescriptor.vertexDescriptor              = depthOnlyVD;
        depthOnlyDescriptor.depthAttachmentPixelFormat    = MTLPixelFormatDepth32Float;
        depthOnlyDescriptor.supportIndirectCommandBuffers = YES;

#if (SUPPORT_SINGLE_PASS_CSM_GENERATION || SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION)
        // Enable vertex amplification - need a minimum of 2 amplification to enable on shaders
        if(genCSMUsingVertexAmplification)
        {
            depthOnlyDescriptor.maxVertexAmplificationCount = 2;
        }
        else if (useSinglePassCSMGeneration)
        {
            depthOnlyDescriptor.maxVertexAmplificationCount = 1;

        }
#endif
        _depthOnlyOpaque = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
        NSAssert(_depthOnlyOpaque, @"Failed to create opaque depth only pipeline state: %@", error);

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        if(genCSMUsingVertexAmplification)
        {
            depthOnlyDescriptor.vertexFunction                = [library newFunctionWithName:@"vertexShaderDepthOnlyAmplified"];
            _depthOnlyAmplifiedOpaque                         = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
            NSAssert(_depthOnlyAmplifiedOpaque, @"Failed to create opaque depth only amplified pipeline state: %@", error);
        }
#endif

        id <MTLFunction> depthOnlyAlphaMaskVertexFunction = [library newFunctionWithName:@"vertexShaderDepthOnlyAlphaMask"];
        id <MTLFunction> depthOnlyAlphaMaskFragmentFunction = [library newFunctionWithName:@"fragmentShaderDepthOnlyAlphaMask"];

        depthOnlyDescriptor.label                         = @"DepthOnlyPipelineState_AlphaMask";
        depthOnlyDescriptor.vertexFunction                = depthOnlyAlphaMaskVertexFunction;
        depthOnlyDescriptor.fragmentFunction              = depthOnlyAlphaMaskFragmentFunction;
        depthOnlyDescriptor.vertexDescriptor              = depthOnlyAlphaMaskVD;

        _depthOnlyAlphaMask = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
        NSAssert(_depthOnlyAlphaMask, @"Failed to create alpha mask depth only pipeline state: %@", error);

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        if(genCSMUsingVertexAmplification)
        {
            depthOnlyDescriptor.vertexFunction                = [library newFunctionWithName:@"vertexShaderDepthOnlyAlphaMaskAmplified"];
            _depthOnlyAmplifiedAlphaMask                      = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
            NSAssert(_depthOnlyAmplifiedAlphaMask, @"Failed to create alpha mask depth only amplified pipeline state: %@", error);
        }
#endif

#if (SUPPORT_SINGLE_PASS_CSM_GENERATION || SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION)
        // Reset vertex amplification to disabled
        if(genCSMUsingVertexAmplification)
        {
            depthOnlyDescriptor.maxVertexAmplificationCount = 1;
        }
#endif

#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
        id <MTLFunction> depthOnlyTileFragmentFunction          = [library newFunctionWithName:@"fragmentShaderDepthOnlyTile"];
        id <MTLFunction> depthOnlyTileAlphaMaskFragmentFunction = [library newFunctionWithName:@"fragmentShaderDepthOnlyTileAlphaMask"];

        depthOnlyDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatR32Float;

        depthOnlyDescriptor.label               = @"DepthOnlyTilePipelineState";
        depthOnlyDescriptor.vertexFunction      = depthOnlyVertexFunction;
        depthOnlyDescriptor.fragmentFunction    = depthOnlyTileFragmentFunction;

        _depthOnlyTileOpaque = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
        NSAssert(_depthOnlyTileOpaque, @"Failed to create opaque depth only tile pipeline state: %@", error);

        depthOnlyDescriptor.label               = @"DepthOnlyTilePipelineState_AlphaMask";
        depthOnlyDescriptor.vertexFunction      = depthOnlyAlphaMaskVertexFunction;
        depthOnlyDescriptor.fragmentFunction    = depthOnlyTileAlphaMaskFragmentFunction;

        _depthOnlyTileAlphaMask                 = [_device newRenderPipelineStateWithDescriptor:depthOnlyDescriptor error:&error];
        NSAssert(_depthOnlyTileAlphaMask, @"Failed to create alpha mask depth only tile pipeline state: %@", error);
#endif // SUPPORT_DEPTH_PREPASS_TILE_SHADERS
    }

    // ----------------------------------
    // GBuffer pipeline states
    // ----------------------------------
    {
        MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];

        id <MTLFunction> fragmentGBufferFunctionOpaqueICB = [library newFunctionWithName:@"fragmentGBufferShader" constantValues:fc error:&error];
        NSAssert(fragmentGBufferFunctionOpaqueICB, @"Failed to create gbuffer fragment function (ICB): %@", error);

        [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];

        id <MTLFunction> fragmentGBufferFunctionAlphaMaskICB = [library newFunctionWithName:@"fragmentGBufferShader" constantValues:fc error:&error];
        NSAssert(fragmentGBufferFunctionAlphaMaskICB, @"Failed to create gbuffer alpha mask fragment function (ICB): %@", error);

        MTLRenderPipelineDescriptor *rpd = [[MTLRenderPipelineDescriptor alloc] init];
        rpd.label                          = @"Mesh_GBufferPipelineState_Opaque_ICB";
        rpd.sampleCount                    = sampleCount;
        rpd.vertexFunction                 = vertexFunction;
        rpd.fragmentFunction               = fragmentGBufferFunctionOpaqueICB;
        rpd.vertexDescriptor               = vd;
        rpd.depthAttachmentPixelFormat     = depthStencilFormat;
        rpd.supportIndirectCommandBuffers  = YES;

        uint GBufferIndexStart = AAPLTraditionalGBufferStart;

#if SUPPORT_SINGLE_PASS_DEFERRED
        if(singlePassDeferredLighting)
        {
            GBufferIndexStart = AAPLGBufferLightIndex;
        }
#endif

        for (uint GBufferIndex = GBufferIndexStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
            rpd.colorAttachments[GBufferIndex].pixelFormat = GBufferPixelFormats[GBufferIndex];

        _gBufferOpaque = [_device newRenderPipelineStateWithDescriptor:rpd error:&error];
        NSAssert(_gBufferOpaque, @"Failed to create mesh gbuffer opaque ICB pipeline state: %@", error);

        rpd.label = @"Mesh_GBufferPipelineState_AlphaMask_ICB";
        rpd.fragmentFunction = fragmentGBufferFunctionAlphaMaskICB;

        _gBufferAlphaMask = [_device newRenderPipelineStateWithDescriptor:rpd error:&error];
        NSAssert(_gBufferAlphaMask, @"Failed to create gbuffer alpha mask ICB pipeline state: %@", error);

        {
            [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
            id <MTLFunction> fragmentGBufferFunctionICBDebug = [library newFunctionWithName:@"fragmentGBufferShader"
                                                                                    constantValues:fc
                                                                                             error:&error];

            NSAssert(fragmentGBufferFunctionICBDebug, @"Failed to create mesh gbuffer debug fragment function (ICB): %@", error);

            rpd.label = @"Mesh_GBufferPipelineState_ICB_Debug";
            rpd.fragmentFunction = fragmentGBufferFunctionICBDebug;

            _gBufferDebug = [_device newRenderPipelineStateWithDescriptor:rpd error:&error];
            NSAssert(_gBufferDebug, @"Failed to create gbuffer pipeline state (debug): %@", error);
        }
    }
}

-(void)prerender:(AAPLMesh*)mesh
          passes:(NSArray*)passes
          direct:(BOOL)direct
         icbData:(AAPLICBData&)icbData
           flags:(NSDictionary*)flags
       onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder
{
    if(!direct)
    {
        [encoder useResource:mesh.indices usage:MTLResourceUsageRead];
        [encoder useResource:mesh.vertices usage:MTLResourceUsageRead];
        [encoder useResource:mesh.normals usage:MTLResourceUsageRead];
        [encoder useResource:mesh.tangents usage:MTLResourceUsageRead];
        [encoder useResource:mesh.uvs usage:MTLResourceUsageRead];
    }
}

-(void)render:(AAPLMesh*)mesh
         pass:(AAPLRenderPass)pass
       direct:(BOOL)direct
      icbData:(AAPLICBData&)icbData
        flags:(NSDictionary*)flags
 cameraParams:(AAPLCameraParams&)cameraParams
    onEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder
{
    bool cullingVisualizationMode   = [flags[@"cullingVisualizationMode"] boolValue];
    bool debugView                  = [flags[@"debugView"] boolValue];
    bool clusteredLighting          = [flags[@"clusteredLighting"] boolValue];
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    bool amplifyRendering           = [flags[@"amplify"] boolValue];
#endif
#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
    bool useTileShader              = [flags[@"useTileShader"] boolValue];
#endif

    id <MTLRenderPipelineState> pipelineState = nil;
    if(pass == AAPLRenderPassDepth)
    {
#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
        if(useTileShader)
            pipelineState = _depthOnlyTileOpaque;
        else
#endif
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        if(amplifyRendering)
            pipelineState = _depthOnlyAmplifiedOpaque;
        else
#endif
            pipelineState = _depthOnlyOpaque;  
    }
    else if(pass == AAPLRenderPassDepthAlphaMasked)
    {
#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
        if(useTileShader)
            pipelineState = _depthOnlyTileAlphaMask;
        else
#endif
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        if(amplifyRendering)
            pipelineState = _depthOnlyAmplifiedAlphaMask;
        else
#endif
            pipelineState = _depthOnlyAlphaMask;
    }

    else if(pass == AAPLRenderPassGBuffer)
        pipelineState = _gBufferOpaque;
    else if(pass == AAPLRenderPassGBufferAlphaMasked)
        pipelineState = _gBufferAlphaMask;
    else if(pass == AAPLRenderPassForward)
        pipelineState = _forwardOpaque;
    else if(pass == AAPLRenderPassForwardAlphaMasked)
        pipelineState = _forwardAlphaMask;
    else if(pass == AAPLRenderPassForwardTransparent)
        pipelineState = clusteredLighting ? _forwardTransparentLightCluster : _forwardTransparent;
    else
        assert(false && "Unsupported pass type");

    if(cullingVisualizationMode)
    {
        if(pass == AAPLRenderPassGBuffer || pass == AAPLRenderPassGBufferAlphaMasked)
            pipelineState = _gBufferDebug;
    }

    if(debugView)
    {
        if(pass == AAPLRenderPassForward)
            pipelineState = _forwardOpaqueDebug;
        else if(pass == AAPLRenderPassForwardAlphaMasked)
            pipelineState = _forwardAlphaMaskDebug;
        else if(pass == AAPLRenderPassForwardTransparent)
            pipelineState = _forwardTransparentDebug;
    }

    if(pass == AAPLRenderPassForwardTransparent && clusteredLighting)
    {
        if(debugView)
            pipelineState = _forwardTransparentLightClusterDebug;
        else
            pipelineState = _forwardTransparentLightCluster;
    }

    if(pipelineState == nil)
        return;

    [encoder setRenderPipelineState:pipelineState];

    if(pass == AAPLRenderPassDepthAlphaMasked
       || pass == AAPLRenderPassGBufferAlphaMasked
       || pass == AAPLRenderPassForwardAlphaMasked
       || pass == AAPLRenderPassForwardTransparent
       )
    {
        [encoder setCullMode:MTLCullModeNone];
    }

    size_t materialSize = direct ? _alignedMaterialSize : _materialSize;

    [_textureManager makeResidentForEncoder:encoder];

    if(direct)
    {
        [encoder setVertexBuffer:mesh.vertices offset:0 atIndex:AAPLBufferIndexVertexMeshPositions];
        [encoder setVertexBuffer:mesh.normals offset:0 atIndex:AAPLBufferIndexVertexMeshNormals];
        [encoder setVertexBuffer:mesh.tangents offset:0 atIndex:AAPLBufferIndexVertexMeshTangents];
        [encoder setVertexBuffer:mesh.uvs offset:0 atIndex:AAPLBufferIndexVertexMeshGenerics];

        const AAPLSubMesh* submeshes    = nil;
        NSUInteger submeshCount         = 0;

        if(pass == AAPLRenderPassDepth || pass == AAPLRenderPassGBuffer || pass == AAPLRenderPassForward)
        {
            submeshes       = mesh.meshes;
            submeshCount    = mesh.opaqueMeshCount;
        }
        else if(pass == AAPLRenderPassDepthAlphaMasked || pass == AAPLRenderPassGBufferAlphaMasked || pass == AAPLRenderPassForwardAlphaMasked)
        {
            submeshes       = mesh.meshes + mesh.opaqueMeshCount;
            submeshCount    = mesh.alphaMaskedMeshCount;
        }
        else if(pass == AAPLRenderPassForwardTransparent)
        {
            submeshes       = mesh.meshes + mesh.opaqueMeshCount + mesh.alphaMaskedMeshCount;
            submeshCount    = mesh.transparentMeshCount;
        }
        else
        {
            assert(false && "Unsupported pass type");
        }

        [self drawSubMeshes:submeshes
                      count:submeshCount
                indexBuffer:mesh.indices
                  chunkData:mesh.chunkData
          setMaterialOffset:pass != AAPLRenderPassDepth
               materialSize:materialSize
               cameraParams:cameraParams
                  onEncoder:encoder];
    }
    else
    {
        id<MTLIndirectCommandBuffer> cmdBuffer  = nil;
        NSUInteger executionRangeOffset         = 0;

        if(pass == AAPLRenderPassDepth)
        {
            cmdBuffer               = icbData.commandBuffer_depthOnly;
            executionRangeOffset    = 0;
        }
        else if(pass == AAPLRenderPassDepthAlphaMasked)
        {
            cmdBuffer               = icbData.commandBuffer_depthOnly_alphaMask;
            executionRangeOffset    = sizeof(MTLIndirectCommandBufferExecutionRange);
        }
        else if(pass == AAPLRenderPassGBuffer
                || pass == AAPLRenderPassForward)
        {
            cmdBuffer               = icbData.commandBuffer;
            executionRangeOffset    = 0;
        }
        else if(pass == AAPLRenderPassGBufferAlphaMasked
                || pass == AAPLRenderPassForwardAlphaMasked)
        {
            cmdBuffer               = icbData.commandBuffer_alphaMask;
            executionRangeOffset    = sizeof(MTLIndirectCommandBufferExecutionRange);
        }
        else if(pass == AAPLRenderPassForwardTransparent)
        {
            cmdBuffer               = icbData.commandBuffer_transparent;
            executionRangeOffset    = sizeof(MTLIndirectCommandBufferExecutionRange) * 2;
        }
        else
        {
            assert(false && "Unsupported pass type");
        }

        [encoder executeCommandsInBuffer:cmdBuffer
                          indirectBuffer:icbData.executionRangeBuffer
                    indirectBufferOffset:executionRangeOffset];
    }
}

-(void)drawSubMeshes:(const AAPLSubMesh*)meshes
               count:(NSUInteger)count
         indexBuffer:(id<MTLBuffer>)indexBuffer
           chunkData:(const AAPLMeshChunk*)chunkData
   setMaterialOffset:(BOOL)setMaterialOffset
        materialSize:(size_t)materialSize
        cameraParams:(AAPLCameraParams&)cameraParams
           onEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    for (NSUInteger i = 0; i < count; ++i)
    {
        const AAPLSubMesh &mesh = meshes[i];

        if(setMaterialOffset)
            [renderEncoder setFragmentBufferOffset:mesh.materialIndex * materialSize atIndex:AAPLBufferIndexFragmentMaterial];

#if 0 // one draw per chunk or full mesh
        for (NSUInteger c = mesh.chunkStart; c < (mesh.chunkStart + mesh.chunkCount); ++c)
        {
            const AAPLMeshChunk &chunk = chunkData[c];

            const bool frustumCulled = !sphereInFrustum(cameraParams, chunk.boundingSphere);

            if (frustumCulled)
                continue;

            [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                      indexCount:chunk.indexCount
                                       indexType:MTLIndexTypeUInt32
                                     indexBuffer:indexBuffer
                               indexBufferOffset:chunk.indexBegin * sizeof(uint32_t)];
        }
#else
        const bool frustumCulled = !sphereInFrustum(cameraParams, mesh.boundingSphere);

        if (frustumCulled)
            continue;

        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:mesh.indexCount
                                   indexType:MTLIndexTypeUInt32
                                 indexBuffer:indexBuffer
                           indexBufferOffset:mesh.indexBegin * sizeof(uint32_t)];
#endif
    }
}

@end
