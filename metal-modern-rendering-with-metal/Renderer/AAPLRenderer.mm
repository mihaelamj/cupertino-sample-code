/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a renderer class, which manages render state and performs per-frame rendering.
*/

#import "AAPLRenderer.h"
#import "AAPLMesh.h"
#import "AAPLTextureManager.h"

#import "AAPLDebugRender.h"

#import "AAPLDepthPyramid.h"
#import "AAPLLightCuller.h"
#import "AAPLCulling.h"
#import "AAPLScatterVolume.h"
#import "AAPLAmbientObscurance.h"
#import "AAPLMeshRenderer.h"

#import "AAPLCamera.h"
#import "AAPLCameraController.h"

#import "AAPLLightingEnvironment.h"
#import "AAPLScene.h"
#import "AAPLInput.h"
#import "AAPLCommon.h"
#import "AAPLMaterial.h"
#import "AAPLAsset.h"
#import "AAPLMeshTypes.h"
#import "AAPLUtilities.h"
#import "AAPLMathUtilities.h"
#import "Shaders/AAPLCullingShared.h"

#import "AAPLShaderTypes.h"

#import "AAPLSettingsTableViewController.h"

#import <simd/simd.h>

using namespace simd;

// Options for lighting.
enum AAPLLightingMode
{
    AAPLLightingModeDeferredTiled,      // Deferred with lights filtered per tile.
    AAPLLightingModeDeferredClustered,  // Deferred with lights clustered per tile.
    AAPLLightingModeForward,            // Forward rendering.
};

// Checks if lighting mode is deferred.
static constexpr bool lightingModeIsDeferred(AAPLLightingMode mode)
{
    switch (mode)
    {
        case AAPLLightingModeForward:
            return false;
        case AAPLLightingModeDeferredTiled:
        case AAPLLightingModeDeferredClustered:
            return true;
    }
}

#pragma mark -
#pragma mark Configuration

struct AAPLConfig
{
    AAPLLightingMode    lightingMode;

    AAPLRenderMode      renderMode;
    AAPLRenderCullType  renderCullType;

    AAPLRenderMode      shadowRenderMode;
    AAPLRenderCullType  shadowCullType;

    /// Indicates use of temporal antialiasing in resolve pass
    bool                useTemporalAA;

    /// Indicates use of single pass deferred lighting avaliable to TBDR GPUs.
    bool                singlePassDeferredLighting;

    /// Indicates whether to preform a depth prepass using tiles shaders.
    bool                useDepthPrepassTileShaders;

    /// Indicates use of a tile shader instead of traditional compute kernels to cull lights
    bool                useLightCullingTileShaders;

    /// Indicates use of a tile shader instead of traditional compute kernels downsample depth.
    bool                useDepthDownsampleTileShader;

    /// Indicates use of vertex amplification  to render to all shadow map cascased in a single pass.
    bool                useSinglePassCSMGeneration;

    /// Indicate use of vertex amplification to draw to multiple cascades in with a single draw or execute indirect command.
    bool                genCSMUsingVertexAmplification;

    /// Indicates use of rasterization rate to increase resolution at center of FOV.
    bool                useRasterizationRate;

    /// Indecates whether to page textures onto a sparse heap
    bool                useSparseTextures;

    /// Indicates whether to prefer assets using the ASTC pixel format
    bool                useASTCPixelFormat;
};

#if USE_SPOT_LIGHT_SHADOWS
static constexpr AAPLRenderMode SpotShadowRenderMode = AAPLRenderModeDirect;
#endif

// GBuffer depth and stencil formats.
static constexpr MTLPixelFormat DepthStencilFormat = MTLPixelFormatDepth32Float;
static constexpr MTLPixelFormat LightingPixelFormat = MTLPixelFormatRGBA16Float;
static constexpr MTLPixelFormat HistoryPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

static constexpr MTLPixelFormat GBufferPixelFormats[] =
{
#if SUPPORT_SINGLE_PASS_DEFERRED
    USE_RESOLVE_PASS ? LightingPixelFormat : MTLPixelFormatBGRA8Unorm_sRGB,  // Lighting.
#endif
    MTLPixelFormatRGBA8Unorm_sRGB,  // Albedo/Alpha.
    MTLPixelFormatRGBA16Float,      // Nnormal.
    MTLPixelFormatRGBA8Unorm_sRGB,  // Emissive.
    MTLPixelFormatRGBA8Unorm_sRGB,  // F0/Roughness.
};


_Static_assert(AAPLGBufferIndexCount == sizeof(GBufferPixelFormats) / sizeof(MTLPixelFormat),
    "Number of GBuffer Pixel Formats do not match the number of GBufferIndices");

// Shadow configuration.
static const int ShadowMapSize     = 1024;

#if USE_SPOT_LIGHT_SHADOWS
static const int SpotShadowMapSize = 256;
#endif

// Number of views to be rendered. Main view plus shadow cascades.
static const int NUM_VIEWS         = (1 + SHADOW_CASCADE_COUNT);

static const NSUInteger MaxPointLights = 1024;
static const NSUInteger MaxSpotLights  = 1024;

// ----------------------------------

// Internal structure containing the data for each frame.
//  Multiple copies exist to allow updating while others are in flight.
struct AAPLFrameData
{
    id <MTLBuffer>      frameDataBuffer;        // AAPLFrameConstants for this frame.
    AAPLFrameViewData   viewData[NUM_VIEWS];    // Buffers for each view.
    AAPLICBData         viewICBData[NUM_VIEWS]; // ICBs and chunk cull information for each view.

    // Lighting data
    id <MTLBuffer>  pointLightsBuffer;
    id <MTLBuffer>  spotLightsBuffer;
    id <MTLBuffer>  lightParamsBuffer;

    id <MTLBuffer>  pointLightsCullingBuffer;
    id <MTLBuffer>  spotLightsCullingBuffer;
};

@implementation AAPLRenderer
{
    NSMutableString*        _info;

    MTKView*                _view;

    dispatch_semaphore_t    _inFlightSemaphore;
    id <MTLDevice>          _device;
    id <MTLCommandQueue>    _commandQueue;
    id <MTLCommandBuffer>   _lastCommandBuffer;

    // -----------------------
    // Render Pass Resources
    // -----------------------

    // - Forward
    MTLRenderPassDescriptor*    _forwardPassDescriptor;

    // - GBuffer
    MTLRenderPassDescriptor*    _gBufferPassDescriptor;
    id <MTLTexture>             _gBufferTextures[AAPLGBufferIndexCount];

    uint _lightCullingTileSize;
    uint _lightClusteringTileSize;

    // - Depth
    id <MTLTexture>             _depthTexture;
    id <MTLTexture>             _depthPyramidTexture;
#if SUPPORT_LIGHT_CULLING_TILE_SHADERS || SUPPORT_DEPTH_PREPASS_TILE_SHADERS
    id <MTLTexture>             _depthImageblockTexture;
#endif

    // Texture used as a temporary target when _mainViewWidth/Height is smaller
    //  than `_screenWidth` and `_screenHeight`.
    id <MTLTexture>             _mainView;

    // - Shadow
    MTLRenderPassDescriptor*    _shadowPassDescriptor;
    id <MTLTexture>             _shadowMap;
    id <MTLTexture>             _shadowDepthPyramidTexture;
#if USE_SPOT_LIGHT_SHADOWS
    id <MTLTexture>             _spotShadowMaps;
#endif

#if SUPPORT_RASTERIZATION_RATE
    id <MTLRasterizationRateMap> _rateMap;
    id <MTLBuffer>               _rrMapData;
    id <MTLRenderPipelineState>  _rrPipeline;
    id <MTLRenderPipelineState>  _rrPipelineBlend;
#endif

    // Sky rendering pipeline state.
    id <MTLRenderPipelineState> _pipelineStateForwardSkybox;

    // -----------------------
    // Depth stencil states
    // -----------------------

    id <MTLDepthStencilState>   _depthState;
    id <MTLDepthStencilState>   _depthStateLessEqual;
    id <MTLDepthStencilState>   _depthStateEqualNoWrite;
    id <MTLDepthStencilState>   _depthStateAlwaysNoWrite;
    id <MTLDepthStencilState>   _depthStateLessNoWrite;

    // -----------------------
    // Pipeline states
    // -----------------------

    MTLRenderPassDescriptor*    _lightingPassDescriptor;
    id <MTLTexture>             _lightingBuffer;

    id <MTLRenderPipelineState> _lightingDeferredPipelineState;
    id <MTLRenderPipelineState> _lightingDebugDeferredPipelineState;
    id <MTLRenderPipelineState> _lightingTiledPipelineState;
    id <MTLRenderPipelineState> _lightingDebugTiledPipelineState;

    LightCullResult             _culledLights;

    // --

    MTLRenderPassDescriptor*    _resolvePassDescriptor;
    id <MTLTexture>             _history;

    id <MTLRenderPipelineState> _resolvePipelineState;

    // --

    id <MTLRenderPipelineState> _simplePipelineState;
    id <MTLRenderPipelineState> _simplePipelineStateBlend;
    id <MTLRenderPipelineState> _simplePipelineStateDepthOnly;

    id <MTLRenderPipelineState> _simple2DPipelineState;

    id <MTLRenderPipelineState> _resolveCopyToBackBuffer;

    id <MTLRenderPipelineState> _lightHeatmapPipelineState;
    id <MTLRenderPipelineState> _lightClusterHeatmapPipelineState;

#if SUPPORT_DEPTH_DOWNSAMPLE_TILE_SHADER
    id <MTLRenderPipelineState> _depthDownsampleTilePipelineState;
#endif

    // -----------------------
    // Other Resources
    // -----------------------

    // Global textures configuration.
    id <MTLArgumentEncoder> _globalTexturesEncoder;
    id <MTLBuffer>          _globalTexturesBuffer;

    // Material configuration.
    id <MTLArgumentEncoder> _materialEncoder;
    size_t                  _alignedMaterialSize;
#if SUPPORT_MATERIAL_UPDATES
    id <MTLBuffer>          _materialBuffer[MAX_FRAMES_IN_FLIGHT];
    id <MTLBuffer>          _materialBufferAligned[MAX_FRAMES_IN_FLIGHT];
#else
    id <MTLBuffer>          _materialBuffer;
    id <MTLBuffer>          _materialBufferAligned;
#endif

    // Light params configuration.
    id <MTLArgumentEncoder> _lightParamsEncoder;

    // Rendering helper textures.
    id <MTLTexture>         _blueNoiseTexture;
    id <MTLTexture>         _perlinNoiseTexture;
    id <MTLTexture>         _envMapTexture;
    id <MTLTexture>         _dfgLutTexture;

    // -----------------------
    // Virtual Joysticks
    // -----------------------

#if USE_VIRTUAL_JOYSTICKS
    float4x4                    _joystickMatrices[NUM_VIRTUAL_JOYSTICKS];
    id<MTLBuffer>               _circleVB;
    id<MTLBuffer>               _circleIB;
#endif

    // -----------------------
    // Cameras
    // -----------------------

    AAPLCamera*             _viewCamera;
    AAPLCamera*             _secondaryCamera;
    AAPLCameraController*   _cameraController;
    AAPLCameraController*   _secondaryCameraController;
    bool                    _syncSecondaryCamera;
    bool                    _controlSecondaryCamera;

    // Previous view projection matrix for temporal reprojection.
    float4x4                _prevViewProjMatrix;

    AAPLCamera*             _shadowCameras[SHADOW_CASCADE_COUNT];

    // -----------------------
    // State
    // -----------------------

    float3          _sunDirection;

    float3          _windDirection;
    float           _windSpeed;

    float3          _globalNoiseOffset;

    AAPLConfig      _config;
    uint            _lightState; // 0 - Off, 1 - Point, 2 - Point + Spot
    bool            _occludersEnabled;

    // Debug settings.
    uint            _debugView;
    bool            _debugToggle;
    uint            _cullingVisualizationMode;
    uint            _lightHeatmapMode;
    bool            _showLights;
    bool            _showWireframe;
    float           _scatterScaleDebug;
    float           _exposureScaleDebug;
    bool            _debugDrawOccluders;
#if USE_TEXTURE_STREAMING
    uint            _forceTextureSize;
#endif

#if SUPPORT_ON_SCREEN_SETTINGS
    AAPLRenderCullType  _cullTypeDebug;
    uint                _cullingVisualizationModeDebug;
    float               _timeOfDayDebug;
#endif

    // Screen dimensions and view dimensions.
    uint32_t        _screenWidth;
    uint32_t        _screenHeight;
    uint32_t        _mainViewWidth;
    uint32_t        _mainViewHeight;
    uint32_t        _physicalWidth;
    uint32_t        _physicalHeight;

    // Frame information.
    AAPLFrameData   _frameData[MAX_FRAMES_IN_FLIGHT];
    uint8_t         _frameIndex;
    uint32_t        _frameCounter;
    bool            _firstFrame;
    bool            _resetHistory;

    CFAbsoluteTime  _deltaTime;
    CFAbsoluteTime  _currentFrameTime;
    CFAbsoluteTime  _baseTime;

    AAPLTextureManager*             _textureManager;

    // External effects and data.
    AAPLMeshRenderer*               _meshRenderer;
#if USE_SCATTERING_VOLUME
    AAPLScatterVolume*              _scatterVolume;
#endif
    AAPLDepthPyramid*               _depthPyramid;
    AAPLLightCuller*                _lightCuller;
    AAPLCulling*                    _culling;
#if USE_SCALABLE_AMBIENT_OBSCURANCE
    // SAO generation object
    AAPLAmbientObscurance*          _ambientObscurance;

    // A mipped hierarchy of depth maps based on the depth from the last update.
    id <MTLTexture>                 _saoMippedDepth;
#endif

#if ENABLE_DEBUG_RENDERING
    AAPLDebugRender*                _debugRender;
#endif

    AAPLLightingEnvironmentState*   _lightingEnvironment;
    AAPLScene*                      _scene;
    AAPLMesh*                       _mesh;
}

-(NSString*) info { return _info; };

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if(self)
    {
        _info = [NSMutableString new];
        _renderUI = YES;
        _view = view;

        _device = view.device;

        NSLog(@"Using MTLDevice: %@", _device.name);

        NSAssert([_device supportsFamily:MTLGPUFamilyApple3] || [_device supportsFamily:MTLGPUFamilyMac2],
                 @"Indirect command buffers are not supported.");

        _config.lightingMode               = AAPLLightingModeDeferredClustered;

        _config.renderMode                 = AAPLRenderModeIndirect;

        _config.renderCullType             = AAPLRenderCullTypeFrustumDepth;

        _config.shadowRenderMode           = _config.renderMode;

        _config.shadowCullType             = AAPLRenderCullTypeFrustumDepth;

#if SUPPORT_TEMPORAL_ANTIALIASING
        _config.useTemporalAA              = true;
#endif

#if SUPPORT_SINGLE_PASS_DEFERRED
        _config.singlePassDeferredLighting = [_device supportsFamily:MTLGPUFamilyApple1];
#endif

#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS
        _config.useDepthPrepassTileShaders = [_device supportsFamily:MTLGPUFamilyApple4];
#endif

#if SUPPORT_LIGHT_CULLING_TILE_SHADERS
        _config.useLightCullingTileShaders = [_device supportsFamily:MTLGPUFamilyApple4];
#endif

#if SUPPORT_DEPTH_DOWNSAMPLE_TILE_SHADER
        _config.useDepthDownsampleTileShader = [_device supportsFamily:MTLGPUFamilyApple4];
#endif

#if SUPPORT_RASTERIZATION_RATE
        _config.useRasterizationRate = [_device supportsRasterizationRateMapWithLayerCount:1];
#endif

#if SUPPORT_SINGLE_PASS_CSM_GENERATION
        _config.useSinglePassCSMGeneration =  [_device supportsVertexAmplificationCount:1] && [_device supportsFamily:MTLGPUFamilyApple6];
#endif

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        _config.genCSMUsingVertexAmplification = [_device supportsVertexAmplificationCount:2] && _config.useSinglePassCSMGeneration;
#endif

#if SUPPORT_SPARSE_TEXTURES
        _config.useSparseTextures = [_device supportsFamily:MTLGPUFamilyApple6];
#endif

        _config.useASTCPixelFormat = [_device supportsFamily:MTLGPUFamilyApple2];

        _lightCullingTileSize = _config.useLightCullingTileShaders ? TBDR_LIGHT_CULLING_TILE_SIZE : DEFAULT_LIGHT_CULLING_TILE_SIZE;
        _lightClusteringTileSize = _lightCullingTileSize;

        _inFlightSemaphore = dispatch_semaphore_create(MAX_FRAMES_IN_FLIGHT);

        _viewCamera         = [[AAPLCamera alloc] initDefaultPerspective];
        _secondaryCamera    = [[AAPLCamera alloc] initDefaultPerspective];

        _syncSecondaryCamera    = true;
        _controlSecondaryCamera = false;

        _cameraController = [[AAPLCameraController alloc] init];
        [_cameraController attachToCamera:_viewCamera];

        _secondaryCameraController = [[AAPLCameraController alloc] init];
        [_secondaryCameraController attachToCamera:_secondaryCamera];

        // -------

        _cullingVisualizationMode   = 0;
        _debugView                  = 0;
        _debugToggle                = false;

        _lightState                 = 2;
        _scatterScaleDebug          = 2.0f;
        _exposureScaleDebug         = 1.0f;
        _occludersEnabled           = true;

        // -------

#if SUPPORT_ON_SCREEN_SETTINGS
        _cullTypeDebug                  = _config.renderCullType;
        _cullingVisualizationModeDebug  = _cullingVisualizationMode;
        _timeOfDayDebug                 = 2.0f;
#endif

        // -------

        _firstFrame     = true;
        _resetHistory   = true;

        _currentFrameTime = CACurrentMediaTime();
        _baseTime         = CACurrentMediaTime();

        [self loadMetalWithView:view];
        [self loadAssets];

        _lightingEnvironment = [[AAPLLightingEnvironmentState alloc] init];

    }

    return self;
}

// Initializes Metal structures and states for rendering.
- (void)loadMetalWithView:(nonnull MTKView *)view;
{
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;

    // ----------------------------------

    _commandQueue = [_device newCommandQueue];

    // ----------------------------------

    _textureManager = [[AAPLTextureManager alloc] initWithDevice:_device
                                                    commandQueue:_commandQueue
                                                        heapSize:TEXTURE_HEAP_SIZE
                                            permanentTextureSize:64
                                                  maxTextureSize:4096
                                               useSparseTextures:_config.useSparseTextures];

    // ----------------------------------
    // Create shadow maps
    // ----------------------------------

    MTLTextureDescriptor* shadowMapDesc =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                       width:(NSUInteger)ShadowMapSize
                                                      height:(NSUInteger)ShadowMapSize
                                                   mipmapped:false];
    shadowMapDesc.textureType   = MTLTextureType2DArray;
    shadowMapDesc.arrayLength   = SHADOW_CASCADE_COUNT;
    shadowMapDesc.storageMode   = MTLStorageModePrivate;
    shadowMapDesc.usage         = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    _shadowMap                  = [_device newTextureWithDescriptor:shadowMapDesc];
    _shadowMap.label            = @"ShadowMap";

    _shadowDepthPyramidTexture = [AAPLDepthPyramid allocatePyramidTextureFromDepth:_shadowMap
                                                                            device:_device];
    _shadowDepthPyramidTexture.label    = @"ShadowMapDepthPyramid";

#if USE_SPOT_LIGHT_SHADOWS
    MTLTextureDescriptor* spotShadowMapDesc =
    [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                       width:(NSUInteger)SpotShadowMapSize
                                                      height:(NSUInteger)SpotShadowMapSize
                                                   mipmapped:false];

    spotShadowMapDesc.textureType   = MTLTextureType2DArray;
    spotShadowMapDesc.arrayLength   = SPOT_SHADOW_MAX_COUNT;
    spotShadowMapDesc.storageMode   = MTLStorageModePrivate;
    spotShadowMapDesc.usage         = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    _spotShadowMaps                 = [_device newTextureWithDescriptor:spotShadowMapDesc];
    _spotShadowMaps.label           = @"Spot ShadowMap Array";
#endif

    // ----------------------------------
    // ----------------------------------
    // ----------------------------------

    NSError *error;

    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id <MTLFunction> fragmentFunctionOpaqueICB;

    {
        static const bool FALSE_VALUE   = false;

        MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
        [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
        [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];

        // There is a bunch of implicit dependencies on the encoder state, and reinstantiating them seems to blow up stuff.
        // Let's leave them here for now, and live with duplicated code.
        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];
        fragmentFunctionOpaqueICB = [defaultLibrary newFunctionWithName:@"fragmentForwardShader" constantValues:fc error:&error];
    }

    _materialEncoder        = [fragmentFunctionOpaqueICB newArgumentEncoderWithBufferIndex:AAPLBufferIndexFragmentMaterial];
    _globalTexturesEncoder  = [fragmentFunctionOpaqueICB newArgumentEncoderWithBufferIndex:AAPLBufferIndexFragmentGlobalTextures];
    _lightParamsEncoder     = [fragmentFunctionOpaqueICB newArgumentEncoderWithBufferIndex:AAPLBufferIndexFragmentLightParams];

    _alignedMaterialSize = alignUp(_materialEncoder.encodedLength, 256);

    [self resetForCurrentConfigWithView:view library:defaultLibrary];

    _meshRenderer = [[AAPLMeshRenderer alloc] initWithDevice:_device
                                              textureManager:_textureManager
                                                materialSize:_materialEncoder.encodedLength
                                         alignedMaterialSize:_alignedMaterialSize
                                                     library:defaultLibrary
                                         GBufferPixelFormats:GBufferPixelFormats
                                         lightingPixelFormat:LightingPixelFormat
                                          depthStencilFormat:DepthStencilFormat
                                                 sampleCount:view.sampleCount
                                        useRasterizationRate:_config.useRasterizationRate
                                  singlePassDeferredLighting:_config.singlePassDeferredLighting
                                        lightCullingTileSize:_lightCullingTileSize
                                     lightClusteringTileSize:_lightClusteringTileSize
                                  useSinglePassCSMGeneration:_config.useSinglePassCSMGeneration
                              genCSMUsingVertexAmplification:_config.genCSMUsingVertexAmplification];

    _lightCuller = [[AAPLLightCuller alloc] initWithDevice:_device library:defaultLibrary
                                      useRasterizationRate:_config.useRasterizationRate
                                useLightCullingTileShaders:_config.useLightCullingTileShaders
                                      lightCullingTileSize:_lightCullingTileSize
                                   lightClusteringTileSize:_lightClusteringTileSize];

    // If at any point they start depending on RR, it will need to be fixed
#if USE_SCALABLE_AMBIENT_OBSCURANCE
    _ambientObscurance = [[AAPLAmbientObscurance alloc] initWithDevice:_device
                                                               library:defaultLibrary];
#endif

#if USE_SCATTERING_VOLUME
    _scatterVolume = [[AAPLScatterVolume alloc] initWithDevice:_device
                                                       library:defaultLibrary
                                          useRasterizationRate:_config.useRasterizationRate
                                          lightCullingTileSize:_lightCullingTileSize
                                       lightClusteringTileSize:_lightClusteringTileSize];
#endif

    _depthPyramid   = [[AAPLDepthPyramid alloc] initWithDevice:_device
                                                       library:defaultLibrary];

    _culling        = [[AAPLCulling alloc] initWithDevice:_device
                                                  library:defaultLibrary
                                     useRasterizationRate:_config.useRasterizationRate
                           genCSMUsingVertexAmplification:_config.genCSMUsingVertexAmplification];

    // -------------

    _forwardPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _forwardPassDescriptor.depthAttachment.clearDepth        = 1.0f;
    _forwardPassDescriptor.depthAttachment.loadAction        = MTLLoadActionClear;
    _forwardPassDescriptor.depthAttachment.storeAction       = MTLStoreActionDontCare;
    _forwardPassDescriptor.colorAttachments[0].loadAction    = MTLLoadActionClear;
    _forwardPassDescriptor.colorAttachments[0].clearColor    = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
    _forwardPassDescriptor.colorAttachments[0].storeAction   = MTLStoreActionStore;

    // GBuffer

    _gBufferPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _gBufferPassDescriptor.depthAttachment.clearDepth  = 1.0f;
    _gBufferPassDescriptor.depthAttachment.loadAction  = MTLLoadActionClear;
    _gBufferPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;

#if SUPPORT_SINGLE_PASS_DEFERRED
    if(_config.singlePassDeferredLighting)
    {
        _gBufferPassDescriptor.colorAttachments[AAPLGBufferLightIndex].loadAction  = MTLLoadActionDontCare;
        _gBufferPassDescriptor.colorAttachments[AAPLGBufferLightIndex].clearColor  = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
        _gBufferPassDescriptor.colorAttachments[AAPLGBufferLightIndex].storeAction = MTLStoreActionStore;

        for (uint GBufferIndex = AAPLTraditionalGBufferStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
        {
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].loadAction  = MTLLoadActionDontCare;
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].clearColor  = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].storeAction = MTLStoreActionDontCare;
        }
        _gBufferPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
    else
#endif
    {
        for (uint GBufferIndex = AAPLTraditionalGBufferStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
        {
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].loadAction  = MTLLoadActionClear;
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].clearColor  = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
            _gBufferPassDescriptor.colorAttachments[GBufferIndex].storeAction = MTLStoreActionStore;
        }
    }

    // Shadow map
    _shadowPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _shadowPassDescriptor.depthAttachment.texture       = _shadowMap;
    _shadowPassDescriptor.depthAttachment.slice         = 0;
    _shadowPassDescriptor.depthAttachment.clearDepth    = 1.0f;
    _shadowPassDescriptor.depthAttachment.loadAction    = MTLLoadActionClear;
    _shadowPassDescriptor.depthAttachment.storeAction   = MTLStoreActionStore;

    _lightingPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];

    _lightingPassDescriptor.colorAttachments[0].loadAction   = MTLLoadActionDontCare;
    _lightingPassDescriptor.colorAttachments[0].storeAction  = MTLStoreActionStore;

    _resolvePassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    _resolvePassDescriptor.colorAttachments[0].loadAction   = MTLLoadActionDontCare;
    _resolvePassDescriptor.colorAttachments[0].clearColor   = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
    _resolvePassDescriptor.colorAttachments[0].storeAction  = MTLStoreActionStore;

    // ----------------------------------
    // ----------------------------------
    // ----------------------------------

    // depth stencil states
    {
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];

        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled    = YES;
        _depthState                         = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled    = YES;
        _depthStateLessEqual                = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        depthStateDesc.depthCompareFunction = MTLCompareFunctionEqual;
        depthStateDesc.depthWriteEnabled    = NO;
        _depthStateEqualNoWrite             = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        depthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
        depthStateDesc.depthWriteEnabled    = NO;
        _depthStateAlwaysNoWrite            = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

        depthStateDesc.depthCompareFunction    = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled    = NO;
        _depthStateLessNoWrite              = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // ----------------------------------
    // ----------------------------------
    // ----------------------------------

    for(NSUInteger i = 0; i < MAX_FRAMES_IN_FLIGHT; ++i)
    {
        _frameData[i].frameDataBuffer = [_device newBufferWithLength:sizeof(AAPLFrameConstants) options:MTLResourceStorageModeShared];
        _frameData[i].frameDataBuffer.label = @"FrameData";

        for(NSUInteger j = 0; j < NUM_VIEWS; ++j)
        {
            id<MTLBuffer> cameraParamsBuffer = [_device newBufferWithLength:sizeof(AAPLCameraParams) options:MTLResourceStorageModeShared];
            cameraParamsBuffer.label = @"cameraParamsBuffer";

            _frameData[i].viewData[j].cullParamBuffer = cameraParamsBuffer;
            _frameData[i].viewData[j].cameraParamsBuffer = cameraParamsBuffer;

            if (j == 0)
            {
                _frameData[i].viewData[j].cullParamBuffer = [_device newBufferWithLength:sizeof(AAPLCameraParams) options:MTLResourceStorageModeShared];
                _frameData[i].viewData[j].cullParamBuffer.label = @"cullParamBuffer";
            }
        }

        _frameData[i].pointLightsBuffer = [_device newBufferWithLength:sizeof(AAPLPointLightData) * MaxPointLights options:MTLResourceStorageModeShared];
        _frameData[i].pointLightsBuffer.label = @"PointLightsBuffer";

        _frameData[i].pointLightsCullingBuffer = [_device newBufferWithLength:sizeof(AAPLPointLightCullingData) * MaxPointLights options:MTLResourceStorageModeShared];
        _frameData[i].pointLightsCullingBuffer.label = @"PointLightsCullingBuffer";

        _frameData[i].spotLightsBuffer = [_device newBufferWithLength:sizeof(AAPLSpotLightData) * MaxSpotLights options:MTLResourceStorageModeShared];
        _frameData[i].spotLightsBuffer.label = @"SpotLightsBuffer";

        _frameData[i].spotLightsCullingBuffer = [_device newBufferWithLength:sizeof(AAPLSpotLightCullingData) * MaxSpotLights options:MTLResourceStorageModeShared];
        _frameData[i].spotLightsCullingBuffer.label = @"SpotLightsCullingBuffer";

        _frameData[i].lightParamsBuffer = [_device newBufferWithLength:_lightParamsEncoder.encodedLength options:0];
        _frameData[i].lightParamsBuffer.label = @"Light Parameters Buffer";
        [_lightParamsEncoder setArgumentBuffer:_frameData[i].lightParamsBuffer offset:0];
        [_lightParamsEncoder setBuffer:_frameData[i].pointLightsBuffer offset:0 atIndex:AAPLLightParamsIndexPointLights];
        [_lightParamsEncoder setBuffer:_frameData[i].spotLightsBuffer offset:0 atIndex:AAPLLightParamsIndexSpotLights];
    }

#if ENABLE_DEBUG_RENDERING
    _debugRender = [[AAPLDebugRender alloc] initWithDevice:_device];
#endif

    // ----------------------------------
    // ----------------------------------
    // ----------------------------------

#if USE_VIRTUAL_JOYSTICKS
    // Circle VB/IB
    {
        static const int NUM_CIRCLE_SEGMENTS = 64;

        simd::float3 verts[1 + NUM_CIRCLE_SEGMENTS + 1];
        verts[0] = 0.0f;

        for(int i = 0; i < NUM_CIRCLE_SEGMENTS + 1; i++)
        {
            float theta = (float)i/NUM_CIRCLE_SEGMENTS * 2 * M_PI;

            verts[1 + i] = make_float3(sin(theta), cos(theta), 0.0f);
        }

        _circleVB = [_device newBufferWithLength:sizeof(verts) options:0];
        memcpy(_circleVB.contents, verts, sizeof(verts));
        _circleVB.label = @"Joystick Circle Vertices";

        _circleIB = [_device newBufferWithLength:NUM_CIRCLE_SEGMENTS * 3 * sizeof(uint16_t) options:0];
        uint16_t *ib = (uint16_t *)_circleIB.contents;
        _circleIB.label = @"Joystick Circle Indices";

        for(int i = 0; i < NUM_CIRCLE_SEGMENTS; i++)
        {
            *ib++ = 0;
            *ib++ = 1 + i + 0;
            *ib++ = 1 + i + 1;
        }
    }
#endif
}

-(void)resetForCurrentConfigWithView:(MTKView*)view library:(id<MTLLibrary>)library
{

#if SUPPORT_TEMPORAL_ANTIALIASING
    if(_config.useTemporalAA)
    {
        // Set to no in order to support history blit.
        view.framebufferOnly = NO;
    }
#endif

    NSError *error;

    static const bool FALSE_VALUE   = false;

    MTLFunctionConstantValues* fc = [MTLFunctionConstantValues new];

    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexAlphaMask];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTransparent];
    [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexLightCluster];
    [fc setConstantValue:&_config.useRasterizationRate type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexRasterizationRate];
    [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
    [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];


    // ----------------------------------
    // MESH RENDERING STATES
    // ----------------------------------

    id <MTLFunction> FSQuadVertexFunction = [library newFunctionWithName:@"FSQuadVertexShader"];

    // Forward

    {
        id <MTLFunction> fragmentFunctionSkybox = [library newFunctionWithName:@"skyboxShader" constantValues:fc error:&error];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"ForwardPipelineState_Skybox";
        pipelineStateDescriptor.sampleCount                     = view.sampleCount;
        pipelineStateDescriptor.vertexFunction                  = FSQuadVertexFunction;
        pipelineStateDescriptor.fragmentFunction                = fragmentFunctionSkybox;
        pipelineStateDescriptor.vertexDescriptor                = nil;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = LightingPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat      = DepthStencilFormat;
        pipelineStateDescriptor.supportIndirectCommandBuffers   = NO;

        _pipelineStateForwardSkybox = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_pipelineStateForwardSkybox, @"Failed to create forward skybox pipeline state: %@", error);

    }

    // ----------------------------------
    // Initialize render tech
    // ----------------------------------
    [_meshRenderer rebuildPipelinesWithLibrary:library
                           GBufferPixelFormats:GBufferPixelFormats
                           lightingPixelFormat:LightingPixelFormat
                            depthStencilFormat:DepthStencilFormat
                                   sampleCount:view.sampleCount
                          useRasterizationRate:_config.useRasterizationRate
                    singlePassDeferredLighting:_config.singlePassDeferredLighting
                    useSinglePassCSMGeneration:_config.useSinglePassCSMGeneration
                genCSMUsingVertexAmplification:_config.genCSMUsingVertexAmplification];

    [_lightCuller rebuildPipelinesWithLibrary:library
                         useRasterizationRate:_config.useRasterizationRate
                   useLightCullingTileShaders:_config.useLightCullingTileShaders];

    [_culling rebuildPipelinesWithLibrary:library
                     useRasterizationRate:_config.useRasterizationRate
           genCSMUsingVertexAmplification:_config.genCSMUsingVertexAmplification];

#if USE_SCATTERING_VOLUME
    [_scatterVolume rebuildPipelinesWithLibrary:library
                           useRasterizationRate:_config.useRasterizationRate];
#endif
    // ----------------------------------
    // LIGHTING STATES
    // ----------------------------------

    //Lighting Pass
    {
        NSError *error;
        static const bool TRUE_VALUE    = true;
        static const bool FALSE_VALUE   = false;

        [fc setConstantValue:&_config.singlePassDeferredLighting type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexSinglePassDeferred];
        [fc setConstantValue:&_lightCullingTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightCullingTileSize];
        [fc setConstantValue:&_lightClusteringTileSize type:MTLDataTypeUInt atIndex:AAPLFunctionConstIndexLightClusteringTileSize];
        [fc setConstantValue:&TRUE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];

        id <MTLFunction> lightingDebugFragmentFunction = [library newFunctionWithName:@"tiledLightingShader" constantValues:fc error:&error];

        [fc setConstantValue:&FALSE_VALUE type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexDebugView];
        id <MTLFunction> lightingFragmentFunction = [library newFunctionWithName:@"tiledLightingShader" constantValues:fc error:&error];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"LightingPipelineState";
        pipelineStateDescriptor.sampleCount                     = view.sampleCount;
        pipelineStateDescriptor.vertexFunction                  = FSQuadVertexFunction;
        pipelineStateDescriptor.fragmentFunction                = lightingFragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;

#if USE_RESOLVE_PASS
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
#endif

#if SUPPORT_SINGLE_PASS_DEFERRED
        if(_config.singlePassDeferredLighting)
        {
            for (uint GBufferIndex = AAPLTraditionalGBufferStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
            {
                pipelineStateDescriptor.colorAttachments[GBufferIndex].pixelFormat = GBufferPixelFormats[GBufferIndex];
            }
            pipelineStateDescriptor.depthAttachmentPixelFormat = DepthStencilFormat;
        }
#endif

        _lightingTiledPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_lightingTiledPipelineState, @"Failed to create tiled lighting pipeline state: %@", error);

        pipelineStateDescriptor.label            = @"LightingPipelineStateDebug";
        pipelineStateDescriptor.fragmentFunction = lightingDebugFragmentFunction;
        _lightingDebugTiledPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_lightingDebugTiledPipelineState, @"Failed to create debug tiled lighting pipeline state: %@", error);
    }

    // ----------------------------------
    // RESOLVE STATES
    // ----------------------------------

    {
        [fc setConstantValue:&_config.useTemporalAA type:MTLDataTypeBool atIndex:AAPLFunctionConstIndexTemporalAntialiasing];

        id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentResolveShader" constantValues:fc error:&error];

        MTLRenderPipelineDescriptor *pipelineStateDesc = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDesc.label                             = @"ResolvePipelineState";
        pipelineStateDesc.sampleCount                       = 1;
        pipelineStateDesc.vertexFunction                    = FSQuadVertexFunction;
        pipelineStateDesc.fragmentFunction                  = fragmentFunction;
        pipelineStateDesc.colorAttachments[0].pixelFormat   = HistoryPixelFormat;

        _resolvePipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
        NSAssert(_resolvePipelineState, @"Failed to create resolve pipeline state: %@", error);
    }

    // ----------------------------------
    // ----------------------------------

#if SUPPORT_DEPTH_DOWNSAMPLE_TILE_SHADER
    if(_config.useDepthDownsampleTileShader)
    {
        const simd::uint2 tileSize = { TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT };
        const simd::uint2 depthBoundsDispatchSize = { TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT };

        MTLTileRenderPipelineDescriptor *tilePipelineStateDescriptor = [MTLTileRenderPipelineDescriptor new];

        MTLFunctionConstantValues* tileFunctionConstants = [fc copy];
        [tileFunctionConstants setConstantValue:&tileSize type:MTLDataTypeUInt2 atIndex:AAPLFunctionConstIndexTileSize];
        [tileFunctionConstants setConstantValue:&depthBoundsDispatchSize type:MTLDataTypeUInt2 atIndex:AAPLFunctionConstIndexDispatchSize];

        tilePipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatR32Float;

        tilePipelineStateDescriptor.tileFunction = [library newFunctionWithName:@"tileDepthDownsample" constantValues:tileFunctionConstants error:&error];
        _depthDownsampleTilePipelineState = [_device newRenderPipelineStateWithTileDescriptor:tilePipelineStateDescriptor options:MTLPipelineOptionNone reflection:nullptr error:&error];
        NSAssert(_depthDownsampleTilePipelineState, @"Failed to create downsample depth (tiled) tile pipeline state: %@", error);
    }
#endif

    // ----------------------------------
    // SIMPLE  STATES
    // ----------------------------------
    {
        id <MTLFunction> simpleVertexFunction       = [library newFunctionWithName:@"vertexSimpleShader"];
        id <MTLFunction> simpleFragmentFunction     = [library newFunctionWithName:@"fragmentSimpleShader"];
        id <MTLFunction> simpleTexFragmentFunction  = [library newFunctionWithName:@"fragmentSimpleTexShader"];

        // 3D
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"SimplePipelineState";
        pipelineStateDescriptor.sampleCount                     = view.sampleCount;
        pipelineStateDescriptor.vertexFunction                  = simpleVertexFunction;
        pipelineStateDescriptor.fragmentFunction                = simpleFragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat      = DepthStencilFormat;

        NSError *error;
        _simplePipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_simplePipelineState, @"Failed to create simple pipeline state: %@", error);

        pipelineStateDescriptor.label                                           = @"SimplePipelineStateBlend";
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled             = YES;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactorSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactorOneMinusSourceAlpha;
        _simplePipelineStateBlend = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_simplePipelineStateBlend, @"Failed to create simple pipeline state (blending on): %@", error);

        pipelineStateDescriptor.label                                   = @"SimplePipelineStateDepthOnly";
        pipelineStateDescriptor.fragmentFunction                        = nil;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat         = MTLPixelFormatInvalid;
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled     = NO;
        _simplePipelineStateDepthOnly = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_simplePipelineStateDepthOnly, @"Failed to create simple pipeline state (depth only): %@", error);

        // 2D

        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        pipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatInvalid;

        pipelineStateDescriptor.label                           = @"Simple2DPipelineState";
        pipelineStateDescriptor.vertexFunction                  = simpleVertexFunction;
        pipelineStateDescriptor.fragmentFunction                = simpleFragmentFunction;

        _simple2DPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_simple2DPipelineState, @"Failed to create simple 2D pipeline state: %@", error);

        // Fullscreen Quad

        pipelineStateDescriptor.label                           = @"FullScreenTexturedQuadPipelineState";
        pipelineStateDescriptor.vertexFunction                  = FSQuadVertexFunction;
        pipelineStateDescriptor.fragmentFunction                = simpleTexFragmentFunction;

        _resolveCopyToBackBuffer = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_resolveCopyToBackBuffer, @"Failed to create full screen textured quad pipeline state: %@", error);

#if SUPPORT_RASTERIZATION_RATE
        if(_config.useRasterizationRate)
        {
            id <MTLFunction> rrVertex   = [library newFunctionWithName:@"rrVertexSimpleShader"];
            id <MTLFunction> rrFragment = [library newFunctionWithName:@"rrFragmentSimpleShader"];
            pipelineStateDescriptor.label                           = @"RasterizationRatePipelineState";
            pipelineStateDescriptor.depthAttachmentPixelFormat      = MTLPixelFormatInvalid;
            pipelineStateDescriptor.vertexFunction                  = rrVertex;
            pipelineStateDescriptor.fragmentFunction                = rrFragment;

            _rrPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_rrPipeline, @"Failed to create RR pipeline state: %@", error);

            pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;

            pipelineStateDescriptor.label                          = @"RasterizationRateBlendPipelineState";
            _rrPipelineBlend = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_rrPipelineBlend, @"Failed to create RR pipeline state: %@", error);
        }
#endif
    }

    // ----------------------------------

    {
        id <MTLFunction> lightHeatmapFragmentFunction = [library newFunctionWithName:@"fragmentLightHeatmapShader" constantValues:fc error:&error];

        MTLRenderPipelineDescriptor *psd = [[MTLRenderPipelineDescriptor alloc] init];
        psd.label                           = @"DebugTilesPipelineState";
        psd.sampleCount                     = view.sampleCount;
        psd.vertexFunction                  = FSQuadVertexFunction;
        psd.fragmentFunction                = lightHeatmapFragmentFunction;
        psd.colorAttachments[0].pixelFormat = view.colorPixelFormat;

        psd.colorAttachments[0].blendingEnabled             = TRUE;
        psd.colorAttachments[0].rgbBlendOperation           = MTLBlendOperationAdd;
        psd.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactorSourceAlpha;
        psd.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactorOneMinusSourceAlpha;

        NSError *error;
        _lightHeatmapPipelineState = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_lightHeatmapPipelineState, @"Failed to create light heatmap pipeline state: %@", error);

        psd.label            = @"FragmentLightClusterHeatmapShader";
        psd.fragmentFunction = [library newFunctionWithName:@"fragmentLightClusterHeatmapShader" constantValues:fc error:&error];
        _lightClusterHeatmapPipelineState = [_device newRenderPipelineStateWithDescriptor:psd error:&error];
        NSAssert(_lightClusterHeatmapPipelineState, @"Failed to create light cluster heatmap pipeline state: %@", error);
    }
}

// Helper method to load a texture from a file path.
- (id<MTLTexture>)loadTextureFromPath:(NSString *)filePath
{
    static MTKTextureLoader* sLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

    NSDictionary *options =
    @{
      MTKTextureLoaderOptionSRGB:                 @(false),
      MTKTextureLoaderOptionGenerateMipmaps:      @(false),
      MTKTextureLoaderOptionTextureUsage:         @(MTLTextureUsageShaderRead),
      MTKTextureLoaderOptionTextureStorageMode:   @(MTLStorageModePrivate)
      };

    NSURL* url = [[NSBundle mainBundle] URLForResource:filePath withExtension:@""];

    NSError *error;
    id <MTLTexture> texture = [sLoader newTextureWithContentsOfURL:url
                                                           options:options
                                                             error:&error];
    if (texture)
    {
        texture.label = filePath;
    }
    else
    {
        NSString* reason = [NSString stringWithFormat:@"Error loading texture (%@) : %@", filePath, error];
        NSException* exc = [NSException exceptionWithName:@"Texture loading exception"
                                                   reason:reason
                                                 userInfo:nil];
        @throw exc;
    }
    return texture;
}

- (void)configureMaterial:(const AAPLMaterial &)material
{
    NSUInteger baseColorMip = 0;
    NSUInteger metallicRoughnessMip = 0;
    NSUInteger normalMip = 0;
    NSUInteger emissiveMip = 0;

    id<MTLTexture> baseColorTexture         = material.hasBaseColorTexture ? [_textureManager getTexture:material.baseColorTextureHash outCurrentMip:&baseColorMip] : nil;
    id<MTLTexture> metallicRoughnessTexture = material.hasMetallicRoughnessTexture ? [_textureManager getTexture:material.metallicRoughnessHash outCurrentMip:&metallicRoughnessMip] : nil;
    id<MTLTexture> normalTexture            = material.hasNormalMap ? [_textureManager getTexture:material.normalMapHash outCurrentMip:&normalMip] : nil;
    id<MTLTexture> emissiveTexture          = material.hasEmissiveTexture ? [_textureManager getTexture:material.emissiveTextureHash outCurrentMip:&emissiveMip] : nil;

    //--

    [_materialEncoder setTexture:baseColorTexture atIndex:AAPLMaterialIndexBaseColor];
    [_materialEncoder setTexture:normalTexture atIndex:AAPLMaterialIndexNormal];

    //--

    bool* hasMetallicRoughnessData = (bool*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexHasMetallicRoughness];
    *hasMetallicRoughnessData = material.hasMetallicRoughnessTexture;

    if(material.hasMetallicRoughnessTexture)
        [_materialEncoder setTexture:metallicRoughnessTexture atIndex:AAPLMaterialIndexMetallicRoughness];

    //--

    bool* hasEmissiveData = (bool*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexHasEmissive];
    *hasEmissiveData = material.hasEmissiveTexture;

    if(material.hasEmissiveTexture)
        [_materialEncoder setTexture:emissiveTexture atIndex:AAPLMaterialIndexEmissive];

    //--

    float* alpha = (float*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexAlpha];
    *alpha = material.opacity;

    //--

#if SUPPORT_SPARSE_TEXTURES
    if(_config.useSparseTextures)
    {
        uint* mip;
        mip = (uint*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexBaseColorMip];
        *mip = (uint)baseColorMip;
        mip = (uint*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexMetallicRoughnessMip];
        *mip = (uint)metallicRoughnessMip;
        mip = (uint*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexNormalMip];
        *mip = (uint)normalMip;
        mip = (uint*)[_materialEncoder constantDataAtIndex:AAPLMaterialIndexEmissiveMip];
        *mip = (uint)emissiveMip;
    }
#endif // SUPPORT_SPARSE_TEXTURES
}

// Loads the assets for the scene.
- (void)loadAssets
{
    _viewCamera.viewAngle = 65.0f * (M_PI / 180.0f);
    _viewCamera.nearPlane = 0.1f;
    _viewCamera.farPlane = 100.0f;

    // Load scene configuration data
    _scene = [[AAPLScene alloc] initWithDevice:_device];

    [_scene loadFromFile:@"scene" altSource:NO];

#if !USE_LOCAL_LIGHTS
    [_scene clearLights];
#endif

#if USE_SPOT_LIGHT_SHADOWS
    assert(_scene.spotLightCount < SPOT_SHADOW_MAX_COUNT);
#endif

    NSString *filename = nil;

    // BC/DXT texture formats can be used with a sparse texture however `bistro.dxt.bin` is not
    // properly setup for this.  The `bistro.astc.bin` file is properly setup for bliting
    // to a sparse heap so use it when sparseTextures is enabled or BC/DXT formats are not supported
    if(_config.useSparseTextures || _config.useASTCPixelFormat)
    {
        filename = [NSString stringWithFormat:@"%@.astc.bin", _scene.meshFilename];
    }
    else
    {
        filename = [NSString stringWithFormat:@"%@.dxt.bin", _scene.meshFilename];
    }

    // Load assets into metal objects
    _mesh = [[AAPLMesh alloc] initWithMesh:[AAPLMeshData meshWithFilename:filename]
                                    device:_device
                            textureManager:_textureManager];

    //----------------------------------------------------

    _viewCamera.position = _scene.cameraPosition;
    [_viewCamera faceDirection:_scene.cameraDirection withUp:_scene.cameraUp];

    [_cameraController loadKeypointFromFile:_scene.cameraKeypointsFilename];
    [_secondaryCameraController loadKeypointFromFile:_scene.cameraKeypointsFilename];

    //----------------------------------------------------

    _sunDirection = simd::normalize(_scene.sunDirection);

    _windDirection      = make_float3(0.0f, 0.0f, -1.0f);
    _windSpeed          = 0.2f;

    _globalNoiseOffset  = make_float3(0.0f, 0.0f, 0.0f);

    //----------------------------------------------------

    const AAPLMaterial* materials       = _mesh.materials;
    const NSUInteger    numMaterials    = _mesh.materialCount;

#if !SUPPORT_MATERIAL_UPDATES
    _materialBuffer              = [_device newBufferWithLength:(numMaterials * _materialEncoder.encodedLength) options:0];
    _materialBuffer.label        = @"Material Buffer";
    _materialBufferAligned       = [_device newBufferWithLength:(numMaterials * _alignedMaterialSize) options:0];
    _materialBufferAligned.label = @"Material Buffer Aligned";

    for(int i = 0; i < numMaterials; ++i)
    {
        [_materialEncoder setArgumentBuffer:_materialBuffer startOffset:0 arrayElement:i];
        [self configureMaterial:materials[i]];

        [_materialEncoder setArgumentBuffer:_materialBufferAligned startOffset:i * _alignedMaterialSize arrayElement:0];
        [self configureMaterial:materials[i]];
    }
#else
    for(int j = 0; j < MAX_FRAMES_IN_FLIGHT; ++j)
    {
        _materialBuffer[j]              = [_device newBufferWithLength:(numMaterials * _materialEncoder.encodedLength) options:0];
        _materialBuffer[j].label        = @"Material Buffer";
        _materialBufferAligned[j]       = [_device newBufferWithLength:(numMaterials * _alignedMaterialSize) options:0];
        _materialBufferAligned[j].label = @"Material Buffer Aligned";

        for(int i = 0; i < numMaterials; ++i)
        {
            [_materialEncoder setArgumentBuffer:_materialBuffer[j] startOffset:0 arrayElement:i];
            [self configureMaterial:materials[i]];

            [_materialEncoder setArgumentBuffer:_materialBufferAligned[j] startOffset:i * _alignedMaterialSize arrayElement:0];
            [self configureMaterial:materials[i]];
        }
    }
#endif

    //-----------------------------------------------------

    _globalTexturesBuffer = [_device newBufferWithLength:_globalTexturesEncoder.encodedLength options:0];
    _globalTexturesBuffer.label = @"Global Textures Buffer";
    [_globalTexturesEncoder setArgumentBuffer:_globalTexturesBuffer offset:0];
    [_globalTexturesEncoder setTexture:_shadowMap atIndex:AAPLGlobalTextureIndexShadowMap];
#if USE_SPOT_LIGHT_SHADOWS
    [_globalTexturesEncoder setTexture:_spotShadowMaps atIndex:AAPLGlobalTextureIndexSpotShadows];
#endif

    //-----------------------------------------------------
    //-----------------------------------------------------
    //-----------------------------------------------------

    for(NSUInteger i = 0; i < MAX_FRAMES_IN_FLIGHT; ++i)
    {
        for(NSUInteger j = 0; j < NUM_VIEWS; ++j)
        {
            AAPLICBData& viewICBData = _frameData[i].viewICBData[j];

            [_culling initCommandData:viewICBData
                              forMesh:_mesh
                             chunkViz:(j == 0)
                            frameData:_frameData[i].frameDataBuffer
                 globalTexturesBuffer:_globalTexturesBuffer
                    lightParamsBuffer:_frameData[i].lightParamsBuffer];
        }
    }

    _blueNoiseTexture   = [self loadTextureFromPath:@"blueNoise.png"];
    _envMapTexture      = [self loadTextureFromPath:@"san_giuseppe_bridge_4k_ibl.ktx"];
    _dfgLutTexture      = [self loadTextureFromPath:@"DFGLUT.ktx"];
    _perlinNoiseTexture = [self loadTextureFromPath:@"Perlin.ktx"];

    [_globalTexturesEncoder setTexture:_dfgLutTexture atIndex:AAPLGlobalTextureIndexDFG];
    [_globalTexturesEncoder setTexture:_envMapTexture atIndex:AAPLGlobalTextureIndexEnvMap];
    [_globalTexturesEncoder setTexture:_blueNoiseTexture atIndex:AAPLGlobalTextureIndexBlueNoise];
    [_globalTexturesEncoder setTexture:_perlinNoiseTexture atIndex:AAPLGlobalTextureIndexPerlinNoise];

#if USE_SCATTERING_VOLUME
    _scatterVolume.noiseTexture         = _blueNoiseTexture;
    _scatterVolume.perlinNoiseTexture   = _perlinNoiseTexture;
#endif
}

// Updates the shadow cameras for cascaded shadow maps.
- (void)updateShadowCameras
{
    const float minDistance = 0.0001f;
    const float cascadeSplits[3] = { 3.0f / _viewCamera.farPlane, 10.0f / _viewCamera.farPlane, 50.0f / _viewCamera.farPlane };

    static_assert(SHADOW_CASCADE_COUNT <= 3, "Not enough cascade split data");

    const float3* frustumCornersWS = _viewCamera.frustumCorners;

    for (uint i = 0; i < SHADOW_CASCADE_COUNT; ++i)
    {
        float prevSplitDist = i == 0 ? minDistance : cascadeSplits[i - 1];

        float3 sliceCornersWS[8];

        for(uint j = 0; j < 4; ++j)
        {
            float3 cornerRay        = frustumCornersWS[j + 4] - frustumCornersWS[j];
            float3 nearCornerRay    = cornerRay * prevSplitDist;
            float3 farCornerRay     = cornerRay * cascadeSplits[i];
            sliceCornersWS[j + 4]   = frustumCornersWS[j] + farCornerRay;
            sliceCornersWS[j]       = frustumCornersWS[j] + nearCornerRay;
        }

        float3 frustumCenter = 0.0f;

        for(uint j = 0; j < 8; ++j)
            frustumCenter += sliceCornersWS[j];

        frustumCenter /= 8.0f;

        // Calculate the radius of the frustum slice bounding sphere
        float sphereRadius = 0.0f;

        for(uint i = 0; i < 8; ++i)
        {
            float dist = length(sliceCornersWS[i] - frustumCenter);
            sphereRadius = max(sphereRadius, dist);
        }

        // Change radius in 0.5f steps to prevent flickering
        sphereRadius = ceil(sphereRadius * 2.0f) / 2.0f;

        float3 maxExtents = sphereRadius;
        float3 minExtents = -maxExtents;

        float3 cascadeExtents = maxExtents - minExtents;

        // Get position of the shadow camera
        //float3 shadowCameraPos = frustumCenter + _sunDirection * minExtents.z;
        float3 shadowCameraPos = frustumCenter + _sunDirection * 100.0f;

        _shadowCameras[i] = [[AAPLCamera alloc] initParallelWithPosition:shadowCameraPos
                                                               direction:-_sunDirection
                                                                      up:(float3) { 0, 1, 0}
                                                                   width:cascadeExtents.x
                                                                  height:cascadeExtents.y
                                                               nearPlane:0.0f
                                                                //farPlane:cascadeExtents.z];
                                                                farPlane:200.0f];

        AAPLCameraParams cameraParams = _shadowCameras[i].cameraParams;

        {
            // Create the rounding matrix, by projecting the world-space origin and determining
            // the fractional offset in texel space
            float4x4 shadowMatrix = cameraParams.viewProjectionMatrix;
            float4 shadowOrigin = (float4) { 0.0f, 0.0f, 0.0f, 1.0f };
            shadowOrigin = shadowMatrix * shadowOrigin;
            shadowOrigin *= (ShadowMapSize / 2.0f);

            float4 roundedOrigin = round(shadowOrigin);
            float4 roundOffset = roundedOrigin - shadowOrigin;
            roundOffset = roundOffset * (2.0f / ShadowMapSize);
            roundOffset.z = 0.0f;

            _shadowCameras[i].projectionOffset = roundOffset.xy;
        }
    }
}

// Helper function to decide if we're following the secondary camera.
- (bool)isFollowingCulling
{
    return (_cullingVisualizationMode != AAPLVisualizationTypeNone
            && _cullingVisualizationMode != AAPLVisualizationTypeChunkIndex
            && _secondaryCameraController.enabled);
}

// Updates the state of the camera based on the current input.
- (void)updateCamera:(nonnull AAPLCamera*)camera
           deltaTime:(float)deltaTime
               input:(const AAPLInput&)input
{
    // camera manipulation through keyboard and mouse
    float translation_speed = 1.5f * deltaTime; // meters
    float rotation_speed = 1.0f * deltaTime; //radians

#if USE_VIRTUAL_JOYSTICKS
    camera.position += camera.forward * input.virtualJoysticks[0].value_y * translation_speed * 5;
    camera.position += camera.right * input.virtualJoysticks[0].value_x * translation_speed * 5;
#endif

    // modifier keys to speed up/slow down the camera
    if ([input.pressedKeys containsObject: @(AAPLControlsFast)])         { translation_speed *= 10;}
    if ([input.pressedKeys containsObject: @(AAPLControlsSlow)])         { translation_speed *= 0.1; rotation_speed *= 0.1f; }

    // action keys to manipulate the camera
    if ([input.pressedKeys containsObject: @(AAPLControlsForward)])      camera.position += camera.forward * translation_speed;
    if ([input.pressedKeys containsObject: @(AAPLControlsStrafeRight)])  camera.position += camera.right * translation_speed;
    if ([input.pressedKeys containsObject: @(AAPLControlsStrafeLeft)])   camera.position += camera.left * translation_speed;
    if ([input.pressedKeys containsObject: @(AAPLControlsStrafeUp)])     camera.position += camera.up * translation_speed;
    if ([input.pressedKeys containsObject: @(AAPLControlsStrafeDown)])   camera.position += camera.down * translation_speed;
    if ([input.pressedKeys containsObject: @(AAPLControlsBackward)])     camera.position += camera.backward * translation_speed;

    if ([input.pressedKeys containsObject: @(AAPLControlsTurnLeft)])
        [camera rotateOnAxis: (simd::float3) {0, 1, 0} radians: rotation_speed ];

    if ([input.pressedKeys containsObject: @(AAPLControlsTurnRight)])
        [camera rotateOnAxis: (simd::float3) {0, 1, 0} radians: -rotation_speed ];

    if ([input.pressedKeys containsObject: @(AAPLControlsTurnUp)])
        [camera rotateOnAxis:camera.right radians: rotation_speed ];

    if ([input.pressedKeys containsObject: @(AAPLControlsTurnDown)])
        [camera rotateOnAxis:camera.right radians: -rotation_speed ];

    if ([input.pressedKeys containsObject: @(AAPLControlsRollLeft)])
        [camera rotateOnAxis:camera.direction radians: -rotation_speed ];

    if ([input.pressedKeys containsObject: @(AAPLControlsRollRight)])
        [camera rotateOnAxis:camera.direction radians: rotation_speed ];

    [camera rotateOnAxis: (simd::float3) {0, 1, 0}  radians: input.mouseDeltaX * -0.02f ];
    [camera rotateOnAxis: camera.right              radians: input.mouseDeltaY * -0.02f ];
}

// Halton sequence generator.
static float halton(uint32_t index, uint32_t base)
{
    float result = 0.0f;

    float f = 1.0f;

    while (index > 0)
    {
        f = f/base;
        result += (index % base) * f;
        index /= base;
    }
    return result;
}

// Updates any state for this frame before encoding rendering commands to our drawable.
- (void)updateFrameState:(const AAPLInput&)input
{
    CFAbsoluteTime currentTime = CACurrentMediaTime();

    _deltaTime          = currentTime - _currentFrameTime;
    _currentFrameTime   = currentTime;

#if SUPPORT_ON_SCREEN_SETTINGS
    _config.renderCullType = _cullTypeDebug;
    _config.shadowCullType = _cullTypeDebug;
#endif

    float taaJitterX = 0.0f;
    float taaJitterY = 0.0f;

    if(_config.useTemporalAA)
    {
        uint32_t taaJitterIndex = (_frameCounter % TAA_JITTER_COUNT) + 1;

        taaJitterX = halton(taaJitterIndex, 2);
        taaJitterY = halton(taaJitterIndex, 3);

        taaJitterX = taaJitterX * 2.0f - 1.0f;
        taaJitterY = taaJitterY * 2.0f - 1.0f;

        taaJitterX /= _mainViewWidth;
        taaJitterY /= _mainViewHeight;
    }

    _viewCamera.projectionOffset    = float2{ taaJitterX, taaJitterY };
    _prevViewProjMatrix             = _viewCamera.cameraParams.viewProjectionMatrix;

    //--------------------------------

    float interp;
    uint envA, envB;
    if(_cameraController.enabled)
    {
        [_cameraController updateTimeInSeconds:_deltaTime];
        [_cameraController getLightEnv:interp outA:envA outB:envB];
        [_lightingEnvironment set:interp a:envA b:envB];
    }
    else if(_secondaryCameraController.enabled)
    {
        [_secondaryCameraController updateTimeInSeconds:_deltaTime];
        [_secondaryCameraController getLightEnv:interp outA:envA outB:envB];
        [_lightingEnvironment set:interp a:envA b:envB];
    }
#if SUPPORT_ON_SCREEN_SETTINGS
    else
    {
        uint envInt = (uint)_timeOfDayDebug;
        uint envA   = envInt % _lightingEnvironment.count;
        uint envB   = (envInt+1) % _lightingEnvironment.count;

        [_lightingEnvironment set:_timeOfDayDebug-envInt a:envA b:envB];
    }
#endif

    //--------------------------------

    AAPLCamera* currCamera = _viewCamera;

    if(_controlSecondaryCamera && !_syncSecondaryCamera)
        currCamera = _secondaryCamera;

    [self updateCamera:currCamera deltaTime:_deltaTime input:input];

    //--------------------------------------------------------------

    if([self isFollowingCulling])
    {
        // primary camera track cull camera during visualization
        [_viewCamera facePoint:(_secondaryCamera.position + _secondaryCamera.forward) withUp:vector3(0.0f, 1.0f, 0.0f)];
    }

    //--------------------------------------------------------------

    _viewCamera.projectionOffset = float2{ taaJitterX, taaJitterY };

    [self updateShadowCameras];

    //--------------------------------------------------------------

    if([input.justDownKeys containsObject: @(AAPLControlsCycleLightEnvironment)])
    {
        [_lightingEnvironment next];
    }

    [_lightingEnvironment update];

    //--------------------------------------------------------------

    _globalNoiseOffset += _windDirection * _windSpeed * _deltaTime;

    //--------------------------------------------------------------

    static const int NUM_DEBUG_VIEWS = 10;

    static AAPLStateToggle stateToggles[] =
    {
        { &_debugToggle,                AAPLControlsToggleDebugK },
        { &_showLights,                 AAPLControlsToggleLightWireframe },
        { &_showWireframe,              AAPLControlsToggleWireframe },
#if SUPPORT_TEMPORAL_ANTIALIASING
        { &_config.useTemporalAA,       AAPLControlsToggleTemporalAA },
#endif
        { &_occludersEnabled,           AAPLControlsToggleOccluders },
        { &_debugDrawOccluders,         AAPLControlsDebugDrawOccluders },
    };

    static AAPLStateCycle stateCycles[] =
    {
        { &_debugView,          AAPLControlsCycleDebugView,         AAPLControlsCycleDebugViewBack, NUM_DEBUG_VIEWS },
        { &_lightHeatmapMode,   AAPLControlsCycleLightHeatmap,      -1, 3 },
        { &_lightState,         AAPLControlsCycleLights,            -1, 3 },
#if USE_TEXTURE_STREAMING
        { &_forceTextureSize,   AAPLControlsCycleTextureStreaming,  -1, 12 },
#endif
    };

    static AAPLStateCycleFloat stateCyclesFloat[] =
    {
        { &_scatterScaleDebug,  AAPLControlsCycleScatterScale,  -1, 7.0f, 1.0f },
    };

    int numStateToggles     = sizeof(stateToggles) / sizeof(AAPLStateToggle);
    int numStateCycles      = sizeof(stateCycles) / sizeof(AAPLStateCycle);
    int numStateCyclesFloat = sizeof(stateCyclesFloat) / sizeof(AAPLStateCycleFloat);

    processStateChanges(numStateToggles, stateToggles, numStateCycles, stateCycles, numStateCyclesFloat, stateCyclesFloat, input.justDownKeys);

    //--------------------------------------------------------------

    if([input.justDownKeys containsObject: @(AAPLControlsToggleFreezeCulling)])
        [self toggleFrozenCulling];

    //--------------------------------------------------------------

    if([input.justDownKeys containsObject: @(AAPLControlsTogglePlayback)])
        [self toggleCameraPlayback];

    //--------------------------------------------------------------
    // Secondary Camera
    //--------------------------------------------------------------

    if([input.justDownKeys containsObject: @(AAPLControlsControlSecondary)])
    {
        _controlSecondaryCamera = !_controlSecondaryCamera;

#if !TARGET_OS_IPHONE
        if(_controlSecondaryCamera)
            [[_view window] setTitle:@"AdvancedRendering - Secondary Camera"];
        else
            [[_view window] setTitle:@"AdvancedRendering"];
#endif
    }

    //--------------------------------------------------------------
    //--------------------------------------------------------------

    if(_syncSecondaryCamera)
    {
        _secondaryCamera.up                 = _viewCamera.up;
        _secondaryCamera.direction          = _viewCamera.direction;
        _secondaryCamera.position           = _viewCamera.position;

        _secondaryCamera.nearPlane          = _viewCamera.nearPlane;
        _secondaryCamera.farPlane           = _viewCamera.farPlane;
        _secondaryCamera.viewAngle          = _viewCamera.viewAngle;
        _secondaryCamera.aspectRatio        = _viewCamera.aspectRatio;
        _secondaryCamera.projectionOffset   = _viewCamera.projectionOffset;
    }

    //--------------------------------------------------------------
    // Update virtual joysticks
    //--------------------------------------------------------------

#if USE_VIRTUAL_JOYSTICKS
    const float aspectRatio = (float)_screenWidth/_screenHeight;
    for(int i = 0; i < NUM_VIRTUAL_JOYSTICKS; ++i)
    {
        float2 position = input.virtualJoysticks[i].pos;
        float scale     = input.virtualJoysticks[i].radius;

        _joystickMatrices[i] = matrix4x4_translation(-1.0f + position.x * 2.0f, 1.0f - position.y * 2.0f, 0.0f) * matrix4x4_scale(scale, scale * aspectRatio, 1.0f);
    }
#endif // USE_VIRTUAL_JOYSTICKS

    //--------------------------------------------------------------
    //--------------------------------------------------------------
#if ENABLE_DEBUG_RENDERING
    {
        // Add debug geometry for rendering
        if(self.isFollowingCulling) // render debug camera object
        {
            float4x4 coneMatrix(0.0f);
            coneMatrix.columns[0].xyz = _secondaryCamera.right;
            coneMatrix.columns[1].xyz = _secondaryCamera.forward * 1.5f;
            coneMatrix.columns[2].xyz = _secondaryCamera.up;
            coneMatrix.columns[3].xyz = _secondaryCamera.position + 0.25f * _secondaryCamera.forward;
            coneMatrix.columns[3].w = 1.0f;

            [_debugRender renderConeAt:coneMatrix
                                 color:simd::float4{0.5f, 0.5f, 0.5f, 1.0f}
                             wireframe:NO];

            float4x4 cubeMatrix(0.0f);
            cubeMatrix.columns[0].xyz = _secondaryCamera.right;
            cubeMatrix.columns[1].xyz = _secondaryCamera.up;
            cubeMatrix.columns[2].xyz = _secondaryCamera.forward;
            cubeMatrix.columns[3].xyz = _secondaryCamera.position;
            cubeMatrix.columns[3].w = 1.0f;

            [_debugRender renderCubeAt:cubeMatrix
                                 color:simd::float4{0.25f, 0.25f, 0.25f, 1.0f}
                             wireframe:NO];
        }

        if (_showLights)
        {
            const AAPLPointLightData* pointLights   = _scene.pointLights;
            const AAPLSpotLightData* spotLights     = _scene.spotLights;

            for(size_t i = 0; i < _scene.pointLightCount; ++i)
            {
                simd::float3 pos    = pointLights[i].posSqrRadius.xyz;
                float radius        = sqrtf(pointLights[i].posSqrRadius.w);
                simd::float4 clr    = make_float4(pointLights[i].color, 1.0f);

                [_debugRender renderSphereAt:pos
                                      radius:radius
                                       color:clr
                                   wireframe:YES];
            }

            // Debug spot lights.
            for(size_t i = 0; i < _scene.spotLightCount; ++i)
            {
                matrix_float4x4 coneMatrix = matrix_look_at_left_hand(spotLights[i].posAndHeight.xyz,
                                                            spotLights[i].posAndHeight.xyz + spotLights[i].dirAndOuterAngle.xyz,
                                                            make_float3(0.0f, 1.0f, 0.0f));

                coneMatrix = simd_inverse(coneMatrix);

                float baseRadius = spotLights[i].posAndHeight.w * tanf(spotLights[i].dirAndOuterAngle.w);
                float height = spotLights[i].posAndHeight.w;

                matrix_float4x4 coneScale = {
                    .columns[0] = { baseRadius, 0.0f, 0.0f, 0.0f },
                    .columns[1] = { 0.0f, height, 0.0f, 0.0f },
                    .columns[2] = { 0.0f, 0.0f, baseRadius, 0.0f },
                    .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f }
                };

                //fix for the cone mesh initial orientation
                matrix_float4x4 rot = matrix4x4_rotation(M_PI/2, make_float3(1,0,0));

                coneMatrix = coneMatrix * rot * coneScale;

                [_debugRender renderConeAt:coneMatrix
                                     color:make_float4(spotLights[i].colorAndInnerAngle.xyz, 1)
                                 wireframe:YES];
            }
        }
    }
#endif // ENABLE_DEBUG_RENDERING

}

#if USE_SPOT_LIGHT_SHADOWS
// Generates shadow maps for spot lights.
- (void)generateSpotShadowMaps
{
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Spot Shadows Command Buffer";

    MTLRenderPassDescriptor *spotShadowPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    spotShadowPassDescriptor.depthAttachment.slice         = 0;
    spotShadowPassDescriptor.depthAttachment.clearDepth    = 1.0f;
    spotShadowPassDescriptor.depthAttachment.loadAction    = MTLLoadActionClear;
    spotShadowPassDescriptor.depthAttachment.storeAction   = MTLStoreActionStore;

    const AAPLSpotLightData* spotLights = _scene.spotLights;

    for(int i = 0; i < SPOT_SHADOW_MAX_COUNT && i < _scene.spotLightCount; ++i)
    {
        AAPLCamera *spotCamera = [[AAPLCamera alloc] initPerspectiveWithPosition:spotLights[i].posAndHeight.xyz
                                                                       direction:spotLights[i].dirAndOuterAngle.xyz
                                                                              up:(float3) { 0, 1, 0}
                                                                       viewAngle: spotLights[i].dirAndOuterAngle.w * 2.0f
                                                                     aspectRatio:1.0f
                                                                       nearPlane:0.1f
                                                                        farPlane:spotLights[i].posAndHeight.w];
        [spotCamera updateState];

        spotShadowPassDescriptor.depthAttachment.texture = _spotShadowMaps;
        spotShadowPassDescriptor.depthAttachment.slice = i;

        id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:spotShadowPassDescriptor];
        encoder.label = [NSString stringWithFormat:@"Spot Shadow %i", i];

        AAPLICBData viewData{};

        AAPLFrameViewData frameViewData{};
        frameViewData.cameraParamsBuffer       = [_device newBufferWithLength:sizeof(AAPLCameraParams) options:MTLResourceStorageModeShared];
        frameViewData.cameraParamsBuffer.label = @"cameraParamsBuffer";

        AAPLCameraParams *cameraParams = (AAPLCameraParams *)frameViewData.cameraParamsBuffer.contents;
        *cameraParams = spotCamera.cameraParams;

        [self drawScene:viewData
          frameViewData:frameViewData
              onEncoder:encoder
             renderMode:SpotShadowRenderMode
                 passes:@[@(AAPLRenderPassDepth),@(AAPLRenderPassDepthAlphaMasked)]
                  flags:nil
             equalDepth:NO];

        [encoder endEncoding];
    }

    [commandBuffer commit];
}
#endif

- (id<MTLBuffer>) getCurrentMaterialBuffer:(BOOL)aligned
{
#if SUPPORT_MATERIAL_UPDATES
    if(aligned)
        return _materialBufferAligned[_frameIndex];
    else
        return _materialBuffer[_frameIndex];
#else
    if(aligned)
        return _materialBufferAligned;
    else
        return _materialBuffer;
#endif
}

// Peforms a single render of the scene based on the specified renderMode.
- (void)        drawScene:(AAPLICBData&)viewICBData
            frameViewData:(AAPLFrameViewData&)frameViewData
                onEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
               renderMode:(AAPLRenderMode)renderMode
                   passes:(NSArray*)passes
                    flags:(NSDictionary*)flags
               equalDepth:(BOOL)equalDepth
{
    NSMutableDictionary* extendedFlags = [NSMutableDictionary new];
    [extendedFlags addEntriesFromDictionary:flags];
    [extendedFlags setValue:@(_cullingVisualizationMode) forKey:@"cullingVisualizationMode"];
    [extendedFlags setValue:@(_debugView) forKey:@"debugView"];
    [extendedFlags setValue:@(_config.lightingMode == AAPLLightingModeDeferredClustered) forKey:@"clusteredLighting"];

    [renderEncoder setFrontFacingWinding:MTLWindingClockwise];

    [renderEncoder useResource:_globalTexturesBuffer usage:MTLResourceUsageRead];

    id<MTLBuffer> frameDataBuffer     = _frameData[_frameIndex].frameDataBuffer;
    id<MTLBuffer> cameraParamsBuffer = frameViewData.cameraParamsBuffer;
    id<MTLBuffer> materialBuffer      = [self getCurrentMaterialBuffer:(renderMode == AAPLRenderModeDirect)];

    AAPLCameraParams *cameraParams = (AAPLCameraParams *)frameViewData.cameraParamsBuffer.contents;

    if (_config.lightingMode == AAPLLightingModeForward)
    {
        [renderEncoder useResource:_frameData[_frameIndex].pointLightsBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:_frameData[_frameIndex].spotLightsBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:_culledLights.pointLightIndicesBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:_culledLights.spotLightIndicesBuffer usage:MTLResourceUsageRead];
    }

    if (renderMode == AAPLRenderModeDirect)
    {
        [renderEncoder setVertexBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setFragmentBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setVertexBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
        [renderEncoder setFragmentBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];

        [renderEncoder setFragmentBuffer:_globalTexturesBuffer offset:0 atIndex:AAPLBufferIndexFragmentGlobalTextures];
        [renderEncoder setFragmentBuffer:_frameData[_frameIndex].lightParamsBuffer offset:0 atIndex:AAPLBufferIndexFragmentLightParams];
        [renderEncoder setFragmentBuffer:viewICBData.chunkVizBuffer offset:0 atIndex:AAPLBufferIndexFragmentChunkViz];

        [renderEncoder setFragmentBuffer:materialBuffer offset:0 atIndex:AAPLBufferIndexFragmentMaterial];
    }
    else
    {
        [renderEncoder useResource:materialBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:cameraParamsBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:frameDataBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:_globalTexturesBuffer usage:MTLResourceUsageRead];
        [renderEncoder useResource:_frameData[_frameIndex].lightParamsBuffer usage:MTLResourceUsageRead];

        if(viewICBData.chunkVizBuffer)
            [renderEncoder useResource:viewICBData.chunkVizBuffer usage:MTLResourceUsageRead];
    }

    [_meshRenderer prerender:_mesh
                      passes:passes
                      direct:(renderMode == AAPLRenderModeDirect)
                     icbData:viewICBData
                       flags:extendedFlags
                   onEncoder:renderEncoder];

    for (NSNumber* p in passes)
    {
        AAPLRenderPass pass = (AAPLRenderPass)[p intValue];

        [renderEncoder setCullMode:MTLCullModeBack];

        if(pass == AAPLRenderPassForwardTransparent)
            [renderEncoder setDepthStencilState:_depthStateLessNoWrite];
        else
            [renderEncoder setDepthStencilState: equalDepth ? _depthStateEqualNoWrite : _depthState];

        [_meshRenderer render:_mesh
                         pass:pass
                       direct:(renderMode == AAPLRenderModeDirect)
                      icbData:viewICBData
                        flags:extendedFlags
               cameraParams:*cameraParams
                    onEncoder:renderEncoder];
    }
}

// Peforms a single render of the scene based on the specified renderMode.
- (void) drawSky:(AAPLFrameViewData&)frameViewData onEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    id<MTLBuffer> frameDataBuffer  = _frameData[_frameIndex].frameDataBuffer;
    id<MTLBuffer> cameraParamsBuffer = frameViewData.cameraParamsBuffer;

    [renderEncoder setRenderPipelineState:_pipelineStateForwardSkybox]; // `skyboxShader`
    [renderEncoder setDepthStencilState:_depthStateLessEqual];

    [renderEncoder setFragmentBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
    [renderEncoder setFragmentBuffer:_globalTexturesBuffer offset:0 atIndex:AAPLBufferIndexFragmentGlobalTextures];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
}

// Draws the occluder geometry for the scene assuming that the encoder and
//  pipeline state have been set.
- (void)drawOccluderGeometry:(id<MTLRenderCommandEncoder>)renderEncoder
              viewProjMatrix:(float4x4)viewProjMatrix
{
    constexpr simd::float4 red = (simd::float4){ 1.0f, 0.0f, 0.0f, 1.0f };

    [renderEncoder setVertexBytes:&viewProjMatrix length:sizeof(viewProjMatrix) atIndex:AAPLBufferIndexCameraParams];
    [renderEncoder setVertexBuffer:_scene.occluderVertexBuffer offset:0 atIndex:AAPLBufferIndexVertexMeshPositions];
    [renderEncoder setFragmentBytes:&red length:sizeof(red) atIndex:AAPLBufferIndexFragmentMaterial];

    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:_scene.occluderIndexBuffer.length / sizeof(uint16_t)
                               indexType:MTLIndexTypeUInt16
                             indexBuffer:_scene.occluderIndexBuffer
                       indexBufferOffset:0];
}

// Draws the occluders for the scene.
//  Used to prepare the depth buffer for occlusion.
- (void)drawOccluders:(id<MTLTexture>)texture
        commandBuffer:(id<MTLCommandBuffer>)commandBuffer
              rateMap:(id<MTLRasterizationRateMap>)rateMap
       viewProjMatrix:(float4x4)viewProjMatrix
{
    MTLRenderPassDescriptor *depthOnlyDescriptor    = [MTLRenderPassDescriptor new];
#if SUPPORT_RASTERIZATION_RATE
    depthOnlyDescriptor.rasterizationRateMap        = rateMap;
#endif
    depthOnlyDescriptor.depthAttachment.texture     = texture;
    depthOnlyDescriptor.depthAttachment.loadAction  = MTLLoadActionClear;
    depthOnlyDescriptor.depthAttachment.clearDepth  = 1.0;
    depthOnlyDescriptor.depthAttachment.storeAction = MTLStoreActionStore;

    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:depthOnlyDescriptor];
    renderEncoder.label = @"RenderOccluders";

    [renderEncoder setRenderPipelineState:_simplePipelineStateDepthOnly];
    [renderEncoder setDepthStencilState:_depthState];

    [self drawOccluderGeometry:renderEncoder viewProjMatrix:viewProjMatrix];

    [renderEncoder endEncoding];
}


#if ENABLE_DEBUG_RENDERING
// Draws a frustum for one camera from the view of another camera.
- (void)drawFrustum:(float4x4)frustumInvViewProjMatrix
     viewProjMatrix:(float4x4)viewProjMatrix
                 on:(id<MTLRenderCommandEncoder>)renderEncoder
           pipeline:(id<MTLRenderPipelineState>)pipelineState
              blend:(id<MTLRenderPipelineState>)pipelineStateBlend
{
    matrix_float4x4 scaleMatrix = {
            .columns[0] = { 2.0f, 0.0f, 0.0f, 0.0f },
            .columns[1] = { 0.0f, 2.0f, 0.0f, 0.0f },
            .columns[2] = { 0.0f, 0.0f, 2.0f, 0.0f },
            .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f }
    };

    float4x4 cubeMatrix = frustumInvViewProjMatrix * scaleMatrix;

    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setTriangleFillMode:MTLTriangleFillModeLines];
    [_debugRender renderDebugMesh:_debugRender.cubeMesh
                   viewProjMatrix:viewProjMatrix
                      worldMatrix:cubeMatrix
                            color:float4{0.2f, 0.2f, 1.0f, 0.3f}
                        onEncoder:renderEncoder];

    [renderEncoder setRenderPipelineState:pipelineStateBlend];
    [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];
    [_debugRender renderDebugMesh:_debugRender.cubeMesh
                   viewProjMatrix:viewProjMatrix
                      worldMatrix:cubeMatrix
                            color:float4{0.2f, 0.2f, 1.0f, 0.3f}
                        onEncoder:renderEncoder];
}


// Renders all the debug information for the frame.
- (void)renderDebug:(id<MTLCommandBuffer>)commandBuffer
             target:(id<MTLTexture>)target
    frameDataBuffer:(id<MTLBuffer>)frameDataBuffer
       cameraParams:(id<MTLBuffer>)cameraParamsBuffer
     viewProjMatrix:(float4x4)viewProjMatrix
         cullCamera:(AAPLCamera*)cullCamera
{
        // 3d debug rendering
    {
        id <MTLRenderPipelineState> pipelineState      = _simplePipelineState;
        id <MTLRenderPipelineState> pipelineStateBlend = _simplePipelineStateBlend;

        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor new];
        passDescriptor.colorAttachments[0].texture     = target;
        passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionLoad;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
#if SUPPORT_RASTERIZATION_RATE
        if (_config.useRasterizationRate)
        {
                // If we used a RRMap for rendering, we cannot use the depth buffer as an attachment (it's the wrong size).
                // Instead, we'll do discard in the fragment shader based on a depth buffer sample (horribly slow ofcourse).
                // Since this is used for debugging only, it's not really a problem.
            pipelineState = _rrPipeline;
            pipelineStateBlend = _rrPipelineBlend;
        }
        else
#endif
        {
            passDescriptor.depthAttachment.texture     = _depthTexture;
            passDescriptor.depthAttachment.loadAction  = MTLLoadActionLoad;
            passDescriptor.depthAttachment.clearDepth  = 1.0f;
            passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        }

        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        renderEncoder.label = @"Debug3D";

        [renderEncoder setRenderPipelineState:pipelineState];
        [renderEncoder setVertexBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
#if SUPPORT_RASTERIZATION_RATE
        [renderEncoder setFragmentBuffer:_rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif
        [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];
        if (passDescriptor.depthAttachment.texture)
        {
            [renderEncoder setDepthStencilState:_depthStateLessNoWrite];
        }
        else
        {
            [renderEncoder setFragmentTexture:_depthTexture atIndex:0];
        }

            // Draw Debug Occluders
        if (_occludersEnabled && _debugDrawOccluders)
        {
            [self drawOccluderGeometry:renderEncoder viewProjMatrix:viewProjMatrix];
        }

            // Render lists of debug meshes
        {
            [_debugRender renderInstances:renderEncoder viewProjMatrix:viewProjMatrix];
        }

            // Debug Render Frozen Frustum
        if(_cullingVisualizationMode != AAPLVisualizationTypeNone && _cullingVisualizationMode > AAPLVisualizationTypeCascadeCount)
        {
            const float4x4 cullInvViewProjMatrix = cullCamera.cameraParams.invViewProjectionMatrix;
            [self drawFrustum:cullInvViewProjMatrix viewProjMatrix:viewProjMatrix on:renderEncoder pipeline:pipelineState blend:pipelineStateBlend];
        }

        [renderEncoder endEncoding];
    }

        // 2d debug renderering
    {
        if(_lightHeatmapMode > 0)
        {
            MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor new];
            passDescriptor.colorAttachments[0].texture     = target;
            passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionLoad;
            passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
            renderEncoder.label = @"Debug2D";

            simd::float4 params = (simd::float4){(float)_culledLights.tileCountX, (float)_culledLights.tileCountY, (float)(_lightHeatmapMode == 2), 0.0f};

            [renderEncoder setDepthStencilState:_depthStateAlwaysNoWrite];
            if (_config.lightingMode == AAPLLightingModeDeferredClustered)
            {
                [renderEncoder setRenderPipelineState:_lightClusterHeatmapPipelineState]; // `fragmentLightClusterHeatmapShader` shader
                [renderEncoder setFragmentBuffer:_culledLights.pointLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
                [renderEncoder setFragmentBuffer:_culledLights.spotLightClusterIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
                [renderEncoder setFragmentBuffer:cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];

                [renderEncoder setFragmentTexture:_depthTexture atIndex:0];

                params.x = _culledLights.tileCountClusterX;
                params.y = _culledLights.tileCountClusterX * _culledLights.tileCountClusterY;
            }
            else
            {
                [renderEncoder setRenderPipelineState:_lightHeatmapPipelineState]; // `fragmentLightHeatmapShader` shader
                [renderEncoder setFragmentBuffer:_culledLights.pointLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
                [renderEncoder setFragmentBuffer:_culledLights.spotLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];
                [renderEncoder setFragmentBuffer:_culledLights.pointLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentPointLightIndices];
                [renderEncoder setFragmentBuffer:_culledLights.spotLightIndicesTransparentBuffer offset:0 atIndex:AAPLBufferIndexTransparentSpotLightIndices];
                [renderEncoder setFragmentBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
            }

#if SUPPORT_RASTERIZATION_RATE
            [renderEncoder setFragmentBuffer:_rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

            [renderEncoder setFragmentBytes:&params length:sizeof(params) atIndex:AAPLBufferIndexHeatmapParams];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [renderEncoder endEncoding];
        }
    }
}
#endif // ENABLE_DEBUG_RENDERING


// Selects the camera used for culling.
- (AAPLCamera *)getCullCamera
{
    return _secondaryCamera;
}

// Updates the GPU copy of buffers for the current frame.
- (void)updateState
{
    AAPLFrameData& currentFrame = _frameData[_frameIndex];

    AAPLCamera* cullCamera      = self.getCullCamera;

    //----------------------------------------
    // Copy all camera data to their respective buffers

    AAPLCameraParams* cameraParams = (AAPLCameraParams*)currentFrame.viewData[0].cameraParamsBuffer.contents;
    *cameraParams = _viewCamera.cameraParams;

    AAPLCameraParams* cullParams = (AAPLCameraParams*)currentFrame.viewData[0].cullParamBuffer.contents;
    *cullParams = cullCamera.cameraParams;

    AAPLCameraParams* shadowCameraParams[SHADOW_CASCADE_COUNT];

    for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
    {
        shadowCameraParams[i]     = (AAPLCameraParams*)currentFrame.viewData[1 + i].cameraParamsBuffer.contents;
        *shadowCameraParams[i]    = _shadowCameras[i].cameraParams;
    }

    //----------------------------------------
    // Update frame data

    AAPLFrameConstants* frameData = (AAPLFrameConstants*)currentFrame.frameDataBuffer.contents;
    frameData->cullParams      = *cullParams;

    for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
        frameData->shadowCameraParams[i] = *shadowCameraParams[i];

    frameData->prevViewProjectionMatrix = _prevViewProjMatrix;
    frameData->oneOverFarDistance = 1.0f / _viewCamera.farPlane;

    AAPLLightingEnvironment env = _lightingEnvironment.currentEnvironment;
    {
        frameData->exposure              = env.exposure * _exposureScaleDebug;
        frameData->localLightIntensity   = env.localLightIntensity;
        frameData->iblScale              = env.iblScale;
        frameData->iblSpecularScale      = env.iblSpecularScale;
        frameData->emissiveScale         = env.emissiveScale;
        frameData->scatterScale          = env.scatterScale * _scatterScaleDebug;
        frameData->wetness               = env.wetness;
    }

    frameData->sunDirection  = _sunDirection;
    frameData->sunColor      = env.sunColor * env.sunIntensity;
    frameData->skyColor      = env.skyColor * env.skyIntensity;

    frameData->globalNoiseOffset = _globalNoiseOffset;

    frameData->lightIndicesParams = (simd::uint4){
        (uint)_culledLights.tileCountX,
        (uint)_culledLights.tileCountClusterX,
        (uint)_culledLights.tileCountClusterX * (uint)_culledLights.tileCountClusterY,
        0u
    };

    frameData->debugView             = _debugView;
    frameData->visualizeCullingMode  = _cullingVisualizationMode;
    frameData->debugToggle           = _debugToggle;
    frameData->frameCounter          = _frameCounter;

    frameData->frameTime = _currentFrameTime - _baseTime;

    frameData->screenSize    = float2{(float)_mainViewWidth, (float)_mainViewHeight};
    frameData->invScreenSize = 1.0f / frameData->screenSize;

    frameData->physicalSize = float2{(float)_physicalWidth, (float)_physicalHeight};
    frameData->invPhysicalSize = 1.0f / frameData->physicalSize;

    //----

    AAPLPointLightData* pointLights = (AAPLPointLightData*)currentFrame.pointLightsBuffer.contents;
    AAPLPointLightCullingData* pointLightCulling = (AAPLPointLightCullingData *)currentFrame.pointLightsCullingBuffer.contents;
    if (_scene.pointLightCount > 0)
    {
        memcpy(pointLights, _scene.pointLights, _scene.pointLightCount * sizeof(AAPLPointLightData));

        for(NSUInteger i = 0; i < _scene.pointLightCount; i++)
        {
            simd::float4 boundingSphere = cameraParams->viewMatrix * make_float4(pointLights[i].posSqrRadius.xyz, 1.0f);

            float radius = sqrtf(pointLights[i].posSqrRadius.w);
            bool transparent_flag = (pointLights[i].flags & LIGHT_FOR_TRANSPARENT_FLAG) > 0;
            boundingSphere.w = transparent_flag ? radius : -radius;

            AAPLPointLightCullingData pointLightCullingData;
            pointLightCullingData.posRadius = boundingSphere;

            pointLightCulling[i] = pointLightCullingData;
        }
    }

    AAPLSpotLightData* spotLights = (AAPLSpotLightData*)currentFrame.spotLightsBuffer.contents;
    AAPLSpotLightCullingData* spotLightCulling = (AAPLSpotLightCullingData *)currentFrame.spotLightsCullingBuffer.contents;
    if (_scene.spotLightCount > 0)
    {
        memcpy(spotLights, _scene.spotLights, _scene.spotLightCount * sizeof(AAPLSpotLightData));
        for(NSUInteger i = 0; i < _scene.spotLightCount; i++)
        {
            simd::float4 boundingSphere = cameraParams->viewMatrix * make_float4(_scene.spotLights[i].boundingSphere.xyz, 1.0f);

            float radius = spotLights[i].boundingSphere.w;
            bool transparent_flag = (spotLights[i].flags & LIGHT_FOR_TRANSPARENT_FLAG) > 0;
            boundingSphere.w = transparent_flag ? radius : -radius;

            spotLights[i].dirAndOuterAngle.w    = cosf(_scene.spotLights[i].dirAndOuterAngle.w);
            spotLights[i].colorAndInnerAngle.w  = cosf(_scene.spotLights[i].colorAndInnerAngle.w);

            simd::float4 viewPosAndHeight = cameraParams->viewMatrix * make_float4(spotLights[i].posAndHeight.xyz, 1.0f);
            viewPosAndHeight.w = spotLights[i].posAndHeight.w;

            simd::float4 viewDirAndOuterAngle = transpose(cameraParams->invViewMatrix) * make_float4(spotLights[i].dirAndOuterAngle.xyz, 0.0f);
            viewDirAndOuterAngle.w = spotLights[i].dirAndOuterAngle.w;

            AAPLSpotLightCullingData spotLightCullingData;
            spotLightCullingData.posRadius          = boundingSphere;
            spotLightCullingData.posAndHeight       = viewPosAndHeight;
            spotLightCullingData.dirAndOuterAngle   = viewDirAndOuterAngle;

            spotLightCulling[i] = spotLightCullingData;
        }
    }

    id <MTLBuffer> pointLightIndicesTransparent;
    id <MTLBuffer> spotLightIndicesTransparent;

    if (_config.lightingMode == AAPLLightingModeDeferredClustered)
    {
        pointLightIndicesTransparent = _culledLights.pointLightClusterIndicesBuffer;
        spotLightIndicesTransparent = _culledLights.spotLightClusterIndicesBuffer;
    }
    else
    {
        pointLightIndicesTransparent = _culledLights.pointLightIndicesTransparentBuffer;
        spotLightIndicesTransparent = _culledLights.spotLightIndicesTransparentBuffer;
    }

    [_lightParamsEncoder setArgumentBuffer:currentFrame.lightParamsBuffer offset:0  ];
    [_lightParamsEncoder setBuffer:_culledLights.pointLightIndicesBuffer offset:0 atIndex:AAPLLightParamsIndexPointLightIndices];
    [_lightParamsEncoder setBuffer:_culledLights.spotLightIndicesBuffer offset:0 atIndex:AAPLLightParamsIndexSpotLightIndices];
    [_lightParamsEncoder setBuffer:pointLightIndicesTransparent offset:0 atIndex:AAPLLightParamsIndexPointLightIndicesTransparent];
    [_lightParamsEncoder setBuffer:spotLightIndicesTransparent offset:0 atIndex:AAPLLightParamsIndexSpotLightIndicesTransparent];

    //----------------------------------------------------

#if USE_TEXTURE_STREAMING
    // Calculate mip required for each texture based on chunk/mesh screen area
    {
        const AAPLCameraParams cameraParams = _viewCamera.cameraParams;
        const float focalLength         = cameraParams.projectionMatrix.columns[0][0];
        const float focalLengthSquared  = focalLength * focalLength;

#if 1 // Show fine-grain bounding spheres around mesh chunks
        const AAPLMeshChunk* chunks = _mesh.chunkData;

        for(int i = 0; i < _mesh.chunkCount; ++i)
        {
            uint32_t materialIndex = _mesh.chunkData[i].materialIndex;
            const AAPLSphere& boundingSphere = chunks[i].boundingSphere;
#else // Show coarse bounnding spheres of full mesh
        const AAPLSubMesh* meshes = _mesh.meshes;

        for(int i = 0; i < _mesh.meshCount; ++i)
        {
            uint32_t materialIndex = meshes[i].materialIndex;
            const AAPLSphere& boundingSphere = meshes[i].boundingSphere;
#endif

            if(sphereInFrustum(cameraParams, boundingSphere))
            {
                float3 origin = (cameraParams.viewMatrix*make_float4(boundingSphere.center.xyz,1.0)).xyz;
                float area;

                if(origin.z <= boundingSphere.radius)
                {
                    area = _mainViewWidth * _mainViewHeight;
                }
                else
                {
                    float radiusSquared = boundingSphere.radius * boundingSphere.radius;
                    float z2            = origin.z*origin.z;
                    float l2            = dot(origin,origin);

                    area = -M_PI * focalLengthSquared * radiusSquared * sqrt(abs((l2-radiusSquared)/(radiusSquared-z2)))/(radiusSquared-z2);
                    area *= _mainViewWidth * _mainViewHeight * 0.25f;

                    assert(area >= 0.0f);
                }

                [_textureManager setRequiredMip:_mesh.materials[materialIndex].baseColorTextureHash screenArea:area];
                [_textureManager setRequiredMip:_mesh.materials[materialIndex].normalMapHash screenArea:area];
                [_textureManager setRequiredMip:_mesh.materials[materialIndex].metallicRoughnessHash screenArea:area];
                [_textureManager setRequiredMip:_mesh.materials[materialIndex].emissiveTextureHash screenArea:area];
            }
        }
    }
#endif

    NSUInteger forceTextureSize = 0;

#if USE_TEXTURE_STREAMING
    if(_forceTextureSize != 0)
        forceTextureSize = 1 << _forceTextureSize;
#endif

    [_textureManager update:_frameIndex deltaTime:_deltaTime forceTextureSize:forceTextureSize];

    //----------------------------------------------------

#if SUPPORT_MATERIAL_UPDATES
    const AAPLMaterial* materials       = _mesh.materials;
    const NSUInteger    numMaterials    = _mesh.materialCount;

    for(int i = 0; i < numMaterials; ++i)
    {
        [_materialEncoder setArgumentBuffer:_materialBuffer[_frameIndex] startOffset:0 arrayElement:i];
        [self configureMaterial:materials[i]];

        [_materialEncoder setArgumentBuffer:_materialBufferAligned[_frameIndex] startOffset:i * _alignedMaterialSize arrayElement:0];
        [self configureMaterial:materials[i]];
    }
#endif
}

- (uint2)getMaxLightCount
{
    return uint2{ (uint)_scene.pointLightCount, (uint)_scene.spotLightCount };
}

// Gets the point and spot light count.
//  Filters the count based on the current debug state.
- (uint2)getLightCount
{
    uint2 lightCount = [self getMaxLightCount];

    if(_lightState == 0)
    {
        lightCount.x = 0;
        lightCount.y = 0;
    }
    else if(_lightState == 1)
    {
        lightCount.y = 0;
    }

    return lightCount;
}

// Encapsulates the different ways of rendering the shadow.
-(void)renderShadowsForFrame:(AAPLFrameData&)currentFrame
             toCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    NSArray* passes = @[@(AAPLRenderPassDepth),@(AAPLRenderPassDepthAlphaMasked)];

#if (SUPPORT_SINGLE_PASS_CSM_GENERATION || SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION)
    if(_config.useSinglePassCSMGeneration)
    {
        _shadowPassDescriptor.depthAttachment.slice = 0;
        _shadowPassDescriptor.renderTargetArrayLength = SHADOW_CASCADE_COUNT;

        id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:_shadowPassDescriptor];
        encoder.label = @"Shadow Cascade Layered";
        [encoder setDepthBias:0.0f slopeScale:2.0f clamp:0];

        for(uint32_t i = 0; i < SHADOW_CASCADE_COUNT; ++i)
        {
            MTLVertexAmplificationViewMapping viewMapping =
                {.viewportArrayIndexOffset = 0, .renderTargetArrayIndexOffset = i};
            [encoder setVertexAmplificationCount:1 viewMappings:&viewMapping];

            NSDictionary* flags = nil;
#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
            if(i == 1 && _config.genCSMUsingVertexAmplification)
            {
                constexpr MTLVertexAmplificationViewMapping viewMappings[] =
                {
                    {.viewportArrayIndexOffset = 0, .renderTargetArrayIndexOffset = 1},
                    {.viewportArrayIndexOffset = 0, .renderTargetArrayIndexOffset = 2}
                };
                [encoder setVertexAmplificationCount:2 viewMappings:viewMappings];

                flags = @{@"amplify":@true};
            }
#endif
            [self drawScene:currentFrame.viewICBData[1 + i]
              frameViewData:currentFrame.viewData[1 + i]
                  onEncoder:encoder
                 renderMode:_config.shadowRenderMode
                     passes:passes
                      flags:flags
                 equalDepth:NO];
        }
        [encoder endEncoding];
    }
    else
#endif // SUPPORT_SINGLE_PASS_CSM_GENERATION || SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
    {
        for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
        {
            _shadowPassDescriptor.depthAttachment.slice = i;

            id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:_shadowPassDescriptor];
            encoder.label = [NSString stringWithFormat:@"Shadow Cascade %i", i];

            [encoder setDepthBias:0.0f slopeScale:2.0f clamp:0];

            [self drawScene:currentFrame.viewICBData[1 + i]
              frameViewData:currentFrame.viewData[1 + i]
                  onEncoder:encoder
                 renderMode:_config.shadowRenderMode
                     passes:passes
                      flags:nil
                 equalDepth:NO];

            [encoder endEncoding];
        }
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    if (_firstFrame)
    {
#if USE_SPOT_LIGHT_SHADOWS
        [self generateSpotShadowMaps];
#endif
    }

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    ++_frameCounter;
    _frameIndex = (_frameIndex + 1) % MAX_FRAMES_IN_FLIGHT;

    AAPLFrameData& currentFrame = _frameData[_frameIndex];

    [self updateState];

    AAPLCamera* cullCamera = self.getCullCamera;
    const float4x4 cullViewProjMatrix = cullCamera.cameraParams.viewProjectionMatrix;

    id <MTLCommandBuffer> offscreenCommandBuffer = [_commandQueue commandBuffer];
    offscreenCommandBuffer.label = @"Offscreen Command Buffer";
    _lastCommandBuffer = offscreenCommandBuffer;

    id <MTLCommandBuffer> onscreenCommandBuffer = [_commandQueue commandBuffer];
    onscreenCommandBuffer.label = @"Onscreen Command Buffer";

    // Delay getting the currentRenderPassDescriptor until absolutely needed. This avoids
    // holding onto the drawable and blocking the display pipeline any longer than necessary
    __block id <MTLCommandBuffer> commandBuffer = offscreenCommandBuffer;
    MTLRenderPassDescriptor *(^getViewRenderPassDescriptor)() = ^() {
        // Kick off offscreen work and switch command buffers
        if (commandBuffer == offscreenCommandBuffer)
        {
            [commandBuffer commit];
            commandBuffer = onscreenCommandBuffer;
        }

        return view.currentRenderPassDescriptor;
    };

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
    {
        self->_info = [NSMutableString new];
        [self->_info appendString:@"Culling Stats:\n"];

        if(self->_config.renderMode == AAPLRenderModeIndirect)
        {
            for(uint i = 0;  i < NUM_VIEWS; ++i)
            {
                const MTLIndirectCommandBufferExecutionRange *range = (const MTLIndirectCommandBufferExecutionRange *)currentFrame.viewICBData[i].executionRangeBuffer.contents;
                NSString* cullInfo = [NSString stringWithFormat:@"View %d: %04d/%04d commands\n", i, range[0].length+range[1].length+range[2].length, (unsigned int)self->_mesh.chunkCount];

                [self->_info appendString:cullInfo];
            }
        }
        dispatch_semaphore_signal(block_sema);

        [self->_info appendString:@"-----\n"];
        [self->_info appendString:self->_textureManager.info];
    }];


    id<MTLBuffer> rrMapData = nil;

#if SUPPORT_RASTERIZATION_RATE
    rrMapData = _rrMapData;
#endif

    uint2 lightCount = self.getLightCount;
    [_lightCuller executeCoarseCulling:_culledLights
                         commandBuffer:commandBuffer
                       pointLightCount:lightCount.x
                        spotLightCount:lightCount.y
                           pointLights:currentFrame.pointLightsCullingBuffer
                            spotLights:currentFrame.spotLightsCullingBuffer
                       frameDataBuffer:currentFrame.frameDataBuffer
                    cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                                rrData:rrMapData
                             nearPlane:_viewCamera.nearPlane];

    id<MTLRasterizationRateMap> rateMap;


#if SUPPORT_RASTERIZATION_RATE
    rateMap = _rateMap;
#endif

    if (_occludersEnabled)
        [self drawOccluders:_depthTexture
              commandBuffer:commandBuffer
                    rateMap:rateMap
             viewProjMatrix:cullViewProjMatrix];

    // Generate depth pyramid and run chunk culling for main view
    if(_config.renderMode == AAPLRenderModeIndirect)
    {
        [_culling resetIndirectCommandBuffersForViews:currentFrame.viewICBData
                                            viewCount:1
                                             mainPass:YES
                                            depthOnly:YES
                                                 mesh:_mesh
                                      onCommandBuffer:commandBuffer];

        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        encoder.label = @"ICBMainViewEncoder";

        AAPLRenderCullType renderCullType = _cullingVisualizationMode ? AAPLRenderCullTypeVisualization : _config.renderCullType;

        // Generate depth pyramid
        {
            bool needsDepthPyramid = (renderCullType == AAPLRenderCullTypeFrustumDepth);

            if(needsDepthPyramid)
                [_depthPyramid generate:_depthPyramidTexture depthTexture:_depthTexture onEncoder:encoder];
        }

        // Execute chunk culling
        [_culling executeCulling:currentFrame.viewICBData[0]
                   frameViewData:currentFrame.viewData[0]
                 frameDataBuffer:currentFrame.frameDataBuffer
                        cullMode:renderCullType
                  pyramidTexture:_depthPyramidTexture
                        mainPass:YES
                       depthOnly:YES
                            mesh:_mesh
                  materialBuffer:[self getCurrentMaterialBuffer:NO]
                          rrData:rrMapData
                       onEncoder:encoder];

        [encoder endEncoding];

        [_culling optimizeIndirectCommandBuffersForViews:currentFrame.viewICBData
                                               viewCount:1
                                                mainPass:YES
                                               depthOnly:YES
                                                    mesh:_mesh
                                         onCommandBuffer:commandBuffer];
    }

#if RENDER_SHADOWS
    if(_config.shadowRenderMode == AAPLRenderModeIndirect)
    {
        id <MTLTexture> shadowSlices[SHADOW_CASCADE_COUNT];
        if(_config.shadowCullType == AAPLRenderCullTypeFrustumDepth)
        {
            for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
            {
                shadowSlices[i] = [_shadowMap newTextureViewWithPixelFormat:MTLPixelFormatDepth32Float
                                                                textureType:MTLTextureType2D
                                                                     levels:NSMakeRange(0, 1)
                                                                     slices:NSMakeRange(i, 1)];

                [self drawOccluders:shadowSlices[i]
                      commandBuffer:commandBuffer
                            rateMap:nil
                     viewProjMatrix:_shadowCameras[i].cameraParams.viewProjectionMatrix];
            }
        }

        [_culling resetIndirectCommandBuffersForViews:(currentFrame.viewICBData + 1)
                                            viewCount:SHADOW_CASCADE_COUNT
                                             mainPass:NO
                                            depthOnly:YES
                                                 mesh:_mesh
                                      onCommandBuffer:commandBuffer];

        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        computeEncoder.label = @"ICBShadowEncoder";

        id <MTLTexture> shadowDepthPyramidSlices[SHADOW_CASCADE_COUNT];
        for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
        {
            shadowDepthPyramidSlices[i] = [_shadowDepthPyramidTexture newTextureViewWithPixelFormat:MTLPixelFormatR32Float
                                                                                        textureType:MTLTextureType2D
                                                                                             levels:NSMakeRange(0, _shadowDepthPyramidTexture.mipmapLevelCount)
                                                                                             slices:NSMakeRange(i, 1)];
        }

        if(_config.shadowCullType == AAPLRenderCullTypeFrustumDepth)
        {
            for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
            {
                [_depthPyramid generate:shadowDepthPyramidSlices[i]
                           depthTexture:shadowSlices[i]
                              onEncoder:computeEncoder];
            }
        }

#if SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION
        if(_config.genCSMUsingVertexAmplification)
        {
            for(int i = 0; i < 2; ++i)
            {
                [_culling executeCulling:currentFrame.viewICBData[1 + i]
                           frameViewData:currentFrame.viewData[1 + i]
                         frameDataBuffer:currentFrame.frameDataBuffer
                                cullMode:_config.shadowCullType
                          pyramidTexture:shadowDepthPyramidSlices[i]
                                mainPass:NO
                               depthOnly:YES
                                    mesh:_mesh
                          materialBuffer:[self getCurrentMaterialBuffer:NO]
                                  rrData:nil
                               onEncoder:computeEncoder];
            }

            // Encode to render geometry only in cascade 2
            {
                int i = 1;
                [_culling executeCullingFiltered:currentFrame.viewICBData[1 + i + 1]
                                  frameViewData1:currentFrame.viewData[1 + i]
                                  frameViewData2:currentFrame.viewData[1 + i + 1]
                                 frameDataBuffer:currentFrame.frameDataBuffer
                                        cullMode:_config.shadowCullType
                                 pyramidTexture1:shadowDepthPyramidSlices[i]
                                 pyramidTexture2:shadowDepthPyramidSlices[i+1]
                                            mesh:_mesh
                                  materialBuffer:[self getCurrentMaterialBuffer:NO]
                                       onEncoder:computeEncoder];
            }
        }
        else // if(!SUPPORT_CSM_GENERATION_WITH_VERTEX_AMPLIFICATION)
#endif
        {
            for(int i = 0; i < SHADOW_CASCADE_COUNT; ++i)
            {
                [_culling executeCulling:currentFrame.viewICBData[1 + i]
                           frameViewData:currentFrame.viewData[1 + i]
                         frameDataBuffer:currentFrame.frameDataBuffer
                                cullMode:_config.shadowCullType
                          pyramidTexture:shadowDepthPyramidSlices[i]
                                mainPass:NO
                               depthOnly:YES
                                    mesh:_mesh
                          materialBuffer:[self getCurrentMaterialBuffer:NO]
                                  rrData:nil
                               onEncoder:computeEncoder];
            }
        }

        [computeEncoder endEncoding];

        [_culling optimizeIndirectCommandBuffersForViews:(currentFrame.viewICBData + 1)
                                               viewCount:SHADOW_CASCADE_COUNT
                                                mainPass:NO
                                               depthOnly:YES
                                                    mesh:_mesh
                                         onCommandBuffer:commandBuffer];
    }
#endif

    id<MTLBuffer> frameDataBuffer = currentFrame.frameDataBuffer;

    const bool isClustered = _config.lightingMode == AAPLLightingModeDeferredClustered;

    // Depth prepass
    //--------------

    MTLRenderPassDescriptor *passDescriptor     = [MTLRenderPassDescriptor new];
    passDescriptor.depthAttachment.texture      = _depthTexture;
    passDescriptor.depthAttachment.loadAction   = MTLLoadActionClear;
    passDescriptor.depthAttachment.clearDepth   = 1.0;
    passDescriptor.depthAttachment.storeAction  = MTLStoreActionStore;
#if SUPPORT_RASTERIZATION_RATE
    passDescriptor.rasterizationRateMap         = _rateMap;
#endif

#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS || SUPPORT_LIGHT_CULLING_TILE_SHADERS
    if(_config.useLightCullingTileShaders || _config.useDepthPrepassTileShaders)
    {
        const NSUInteger depthBoundsSize         = MAX(2 * sizeof(uint), 16);
        const NSUInteger lightCountsSize         = 4 * sizeof(uint);

        const NSUInteger lightIndicesSize        = MAX_LIGHTS_PER_TILE * sizeof(uint8_t);

        const NSUInteger depthBoundsOffset       = 0;
        const NSUInteger lightCountsOffset       = depthBoundsOffset + depthBoundsSize;
        const NSUInteger pointLightIndicesOffset = lightCountsOffset + lightCountsSize;
        const NSUInteger spotLightIndicesOffset  = pointLightIndicesOffset + lightIndicesSize;
        const NSUInteger threadgroupMemorySize   = isClustered ? (spotLightIndicesOffset + lightIndicesSize) : (lightCountsOffset + lightCountsSize);

        passDescriptor.threadgroupMemoryLength  = threadgroupMemorySize;

        passDescriptor.tileWidth                = TILE_SHADER_WIDTH;
        passDescriptor.tileHeight               = TILE_SHADER_HEIGHT;

        passDescriptor.colorAttachments[0].texture     = _depthImageblockTexture;
        passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
        passDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(1.0, 0.0, 0.0, 0.0);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionDontCare;

        id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        encoder.label = @"DepthPrepass+LightCulling";

        if(_showWireframe)
        {
            [encoder setTriangleFillMode:MTLTriangleFillModeLines];
        }

        NSDictionary *flags = @{@"useTileShader":@(_config.useDepthPrepassTileShaders)};

        [self drawScene:currentFrame.viewICBData[0]
          frameViewData:currentFrame.viewData[0]
              onEncoder:encoder
             renderMode:_config.renderMode
                 passes:@[@(AAPLRenderPassDepth),@(AAPLRenderPassDepthAlphaMasked)]
                  flags:flags
             equalDepth:NO];

        [encoder setTriangleFillMode:MTLTriangleFillModeFill];

        [encoder setThreadgroupMemoryLength:depthBoundsSize offset:depthBoundsOffset atIndex:AAPLTileThreadgroupIndexDepthBounds];
        [encoder setThreadgroupMemoryLength:lightCountsSize offset:lightCountsOffset atIndex:AAPLTileThreadgroupIndexLightCounts];

        if (isClustered)
        {
            [encoder setThreadgroupMemoryLength:lightIndicesSize offset:pointLightIndicesOffset atIndex:AAPLTileThreadgroupIndexTransparentPointLights];
            [encoder setThreadgroupMemoryLength:lightIndicesSize offset:spotLightIndicesOffset atIndex:AAPLTileThreadgroupIndexTransparentSpotLights];
        }

#if USE_SCALABLE_AMBIENT_OBSCURANCE && SUPPORT_DEPTH_DOWNSAMPLE_TILE_SHADER
    if(_config.useDepthDownsampleTileShader)
    {
        [encoder setTileTexture:_saoMippedDepth atIndex:0];
        [encoder setRenderPipelineState:_depthDownsampleTilePipelineState];
        [encoder dispatchThreadsPerTile:MTLSizeMake(TILE_SHADER_WIDTH, TILE_SHADER_HEIGHT, 1)];
    }
#endif

        id<MTLBuffer> rrMapData = nil;

#if SUPPORT_RASTERIZATION_RATE
        rrMapData = _rrMapData;
#endif

#if SUPPORT_LIGHT_CULLING_TILE_SHADERS
        if(_config.useLightCullingTileShaders)
        {
            [_lightCuller executeTileCulling:_culledLights
                                   clustered:isClustered
                            pointLightCount:lightCount.x
                               spotLightCount:lightCount.y
                                 pointLights:currentFrame.pointLightsCullingBuffer
                                  spotLights:currentFrame.spotLightsCullingBuffer
                             frameDataBuffer:frameDataBuffer
                          cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                                      rrData:rrMapData
                                depthTexture:_depthTexture
                                   onEncoder:encoder];
        }
#endif // SUPPORT_LIGHT_CULLING_TILE_SHADERS

        [encoder endEncoding];
    }
    else
#endif // SUPPORT_LIGHT_CULLING_TILE_SHADERS
    {

        id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        encoder.label = @"DepthPrepass";

        if(_showWireframe)
        {
            [encoder setTriangleFillMode:MTLTriangleFillModeLines];
        }

        NSDictionary *flags = @{@"useTileShader":@(_config.useDepthPrepassTileShaders)};

        [self drawScene:currentFrame.viewICBData[0]
          frameViewData:currentFrame.viewData[0]
              onEncoder:encoder
             renderMode:_config.renderMode
                 passes:@[@(AAPLRenderPassDepth),@(AAPLRenderPassDepthAlphaMasked)]
                  flags:flags
             equalDepth:NO];

        [encoder endEncoding];
    }

#if USE_SCALABLE_AMBIENT_OBSCURANCE
    {
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        computeEncoder.label = @"Mipped Depth Downsample";

#if SUPPORT_DEPTH_DOWNSAMPLE_TILE_SHADER
        if(_config.useDepthDownsampleTileShader)
        {
            // Mip 0 of _saoMippedDepth is already populated so continue pyramid generation
            [_depthPyramid generate:_saoMippedDepth depthTexture:_saoMippedDepth onEncoder:computeEncoder];
        }
        else
#endif
        {
            [_depthPyramid generate:_saoMippedDepth depthTexture:_depthTexture onEncoder:computeEncoder];
        }

        [computeEncoder endEncoding];

        // Scalable ambient obscurance generation
        [_ambientObscurance update:commandBuffer
                   frameDataBuffer:frameDataBuffer
                cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                             depth:_depthTexture
                      depthPyramid:_saoMippedDepth];
    }
#endif

    if(!_config.useLightCullingTileShaders)
    {
        [_lightCuller executeTraditionalCulling:_culledLights
                                pointLightCount:lightCount.x
                                 spotLightCount:lightCount.y
                                    pointLights:currentFrame.pointLightsCullingBuffer
                                     spotLights:currentFrame.spotLightsCullingBuffer
                                frameDataBuffer:frameDataBuffer
                             cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                                         rrData:rrMapData
                                   depthTexture:_depthTexture
                                onCommandBuffer:commandBuffer];
    }

    if (isClustered && !_config.useLightCullingTileShaders)
    {
        [_lightCuller executeTraditionalClustering:_culledLights
                                     commandBuffer:commandBuffer
                                   pointLightCount:lightCount.x
                                    spotLightCount:lightCount.y
                                       pointLights:currentFrame.pointLightsCullingBuffer
                                        spotLights:currentFrame.spotLightsCullingBuffer
                                   frameDataBuffer:frameDataBuffer
                                cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                                            rrData:rrMapData
         ];
    }

#if RENDER_SHADOWS
    [self renderShadowsForFrame:currentFrame
                toCommandBuffer:commandBuffer];
#endif

#if USE_SCATTERING_VOLUME
    id <MTLBuffer> pointLightIndices;
    id <MTLBuffer> spotLightIndices;

    if (isClustered)
    {
        pointLightIndices = _culledLights.pointLightClusterIndicesBuffer;
        spotLightIndices = _culledLights.spotLightClusterIndicesBuffer;
    }
    else
    {
        pointLightIndices = _culledLights.pointLightIndicesTransparentBuffer;
        spotLightIndices = _culledLights.spotLightIndicesTransparentBuffer;
    }

    [_scatterVolume update:commandBuffer
           frameDataBuffer:frameDataBuffer
          cameraParamsBuffer:currentFrame.viewData[0].cameraParamsBuffer
                 shadowMap:_shadowMap
          pointLightBuffer:currentFrame.pointLightsBuffer
           spotLightBuffer:currentFrame.spotLightsBuffer
         pointLightIndices:pointLightIndices
          spotLightIndices:spotLightIndices
#if USE_SPOT_LIGHT_SHADOWS
          spotLightShadows:_spotShadowMaps
#endif
                    rrData:rrMapData
                 clustered:isClustered
              resetHistory:_resetHistory];

#endif // USE_SCATTERING_VOLUME

    {
        const bool useEqualDepth = USE_EQUAL_DEPTH_TEST;

        if(lightingModeIsDeferred(_config.lightingMode))
        {
            // -----------------------------------------------------------
            // GBuffer
            // -----------------------------------------------------------

            _gBufferPassDescriptor.depthAttachment.texture = _depthTexture;

#if SUPPORT_SINGLE_PASS_DEFERRED
            if(_config.singlePassDeferredLighting)
            {
                _gBufferPassDescriptor.threadgroupMemoryLength  = 0;
                _gBufferPassDescriptor.tileWidth                = TILE_SHADER_WIDTH;
                _gBufferPassDescriptor.tileHeight               = TILE_SHADER_HEIGHT;
            }
#endif

            if(useEqualDepth)
            {
                _gBufferPassDescriptor.depthAttachment.loadAction   = MTLLoadActionLoad;
                _gBufferPassDescriptor.depthAttachment.storeAction  = MTLStoreActionStore;
            }
            else
            {
                _gBufferPassDescriptor.depthAttachment.clearDepth   = 1.0f;
                _gBufferPassDescriptor.depthAttachment.loadAction   = MTLLoadActionClear;
                _gBufferPassDescriptor.depthAttachment.storeAction  = MTLStoreActionStore;
            }

#if SUPPORT_RASTERIZATION_RATE
            _gBufferPassDescriptor.rasterizationRateMap = _rateMap;
#endif

            id <MTLRenderCommandEncoder> renderEncoder;
            renderEncoder       = [commandBuffer renderCommandEncoderWithDescriptor:_gBufferPassDescriptor];
            renderEncoder.label = @"GBuffer Pass";

            if(_showWireframe)
                [renderEncoder setTriangleFillMode:MTLTriangleFillModeLines];

            [self drawScene:currentFrame.viewICBData[0]
              frameViewData:currentFrame.viewData[0]
                  onEncoder:renderEncoder
                 renderMode:_config.renderMode
                     passes:@[@(AAPLRenderPassGBuffer),@(AAPLRenderPassGBufferAlphaMasked)]
                      flags:nil
                 equalDepth:useEqualDepth];

            [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];

#if SUPPORT_SINGLE_PASS_DEFERRED
            if(!_config.singlePassDeferredLighting)
#endif
            {
                [renderEncoder endEncoding];
            }

            // -----------------------------------------------------------
            // Deferred Lighting
            // -----------------------------------------------------------

#if !USE_RESOLVE_PASS
            _lightingPassDescriptor.colorAttachments[0].texture = getViewRenderPassDescriptor().colorAttachments[0].texture;

#if SUPPORT_SINGLE_PASS_DEFERRED
            if(_config.singlePassDeferredLighting)
            {
                _gBufferTextures[AAPLGBufferLightIndex] = _lightingPassDescriptor.colorAttachments[0].texture;
            }
#endif // SUPPORT_SINGLE_PASS_DEFERRED

#endif // USE_RESOLVE_PASS

#if SUPPORT_RASTERIZATION_RATE
            // Because tile shader path will execute in warped space, so should the non-tiled variant.
            // Otherwise we'd need extra shader permutations.
            _lightingPassDescriptor.rasterizationRateMap = _rateMap;
#endif

#if SUPPORT_SINGLE_PASS_DEFERRED
            if(!_config.singlePassDeferredLighting)
#endif
            {
                renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_lightingPassDescriptor];
                renderEncoder.label = @"LightingPassEncoder";
            }

            [renderEncoder setDepthStencilState:_depthStateAlwaysNoWrite];

            [renderEncoder setFragmentBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
            [renderEncoder setFragmentBuffer:currentFrame.viewData[0].cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];
#if SUPPORT_RASTERIZATION_RATE
            [renderEncoder setFragmentBuffer:_rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

            [renderEncoder setFragmentBuffer:currentFrame.pointLightsBuffer offset:0 atIndex:AAPLBufferIndexPointLights];
            [renderEncoder setFragmentBuffer:currentFrame.spotLightsBuffer offset:0 atIndex:AAPLBufferIndexSpotLights];

#if USE_SPOT_LIGHT_SHADOWS
            [renderEncoder setFragmentTexture:_spotShadowMaps atIndex:10];
#endif

            [renderEncoder setFragmentTexture:_blueNoiseTexture atIndex:11];

            [renderEncoder setRenderPipelineState:(_debugView == 0 ? _lightingTiledPipelineState : _lightingDebugTiledPipelineState)];

            [renderEncoder setFragmentBuffer:_culledLights.pointLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexPointLightIndices];
            [renderEncoder setFragmentBuffer:_culledLights.spotLightIndicesBuffer offset:0 atIndex:AAPLBufferIndexSpotLightIndices];

#if SUPPORT_SINGLE_PASS_DEFERRED
            if(!_config.singlePassDeferredLighting)
#endif
            {
                for (uint GBufferIndex = AAPLTraditionalGBufferStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
                {
                    uint GBufferTextureUnitIndex = GBufferIndex - AAPLTraditionalGBufferStart;
                    [renderEncoder setFragmentTexture:_gBufferTextures[GBufferIndex] atIndex:GBufferTextureUnitIndex];
                }
            }

            [renderEncoder setFragmentTexture:_depthTexture atIndex:4];
            [renderEncoder setFragmentTexture:_shadowMap atIndex:5];
#if USE_SCATTERING_VOLUME
            [renderEncoder setFragmentTexture:_scatterVolume.scatteringAccumVolume atIndex:6];
#endif
            [renderEncoder setFragmentTexture:_dfgLutTexture atIndex:7];
            [renderEncoder setFragmentTexture:_envMapTexture atIndex:8];
#if USE_SCALABLE_AMBIENT_OBSCURANCE
            [renderEncoder setFragmentTexture:_ambientObscurance.texture atIndex:9];
#endif
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

            [renderEncoder endEncoding];
        }

        // -----------------------------------------------------------
        // Forward
        // -----------------------------------------------------------

        const bool needsForwardPass = (_config.lightingMode == AAPLLightingModeForward) || _mesh.transparentMeshCount > 0;

        if(needsForwardPass)
        {
            _forwardPassDescriptor.depthAttachment.texture      = _depthTexture;
            _forwardPassDescriptor.colorAttachments[0].texture  = _lightingBuffer;

            if(_config.lightingMode == AAPLLightingModeForward)
                _forwardPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
            else
                _forwardPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;

            if(_config.lightingMode == AAPLLightingModeForward && !useEqualDepth)
            {
                _forwardPassDescriptor.depthAttachment.clearDepth   = 1.0f;
                _forwardPassDescriptor.depthAttachment.loadAction   = MTLLoadActionClear;
                _forwardPassDescriptor.depthAttachment.storeAction  = MTLStoreActionStore;
            }
            else
            {
                _forwardPassDescriptor.depthAttachment.loadAction   = MTLLoadActionLoad;
                _forwardPassDescriptor.depthAttachment.storeAction  = MTLStoreActionDontCare;
            }

#if SUPPORT_RASTERIZATION_RATE
            _forwardPassDescriptor.rasterizationRateMap = _rateMap;
#endif

            id <MTLRenderCommandEncoder> forwardEncoder;
            forwardEncoder       = [commandBuffer renderCommandEncoderWithDescriptor:_forwardPassDescriptor];
            forwardEncoder.label = @"Forward Pass";

            [forwardEncoder useResource:_shadowMap usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
            [forwardEncoder useResource:_envMapTexture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
            [forwardEncoder useResource:_dfgLutTexture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
            [forwardEncoder useResource:_blueNoiseTexture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
            [forwardEncoder useResource:_perlinNoiseTexture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];

#if USE_SCALABLE_AMBIENT_OBSCURANCE
            [forwardEncoder useResource:_ambientObscurance.texture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
#endif

#if USE_SCATTERING_VOLUME
            [forwardEncoder useResource:_scatterVolume.scatteringAccumVolume usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
#endif

#if USE_SPOT_LIGHT_SHADOWS
            [forwardEncoder useResource:_spotShadowMaps usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
#endif

            if(_showWireframe)
                [forwardEncoder setTriangleFillMode:MTLTriangleFillModeLines];

            if(_config.lightingMode == AAPLLightingModeForward)
            {
                [self drawScene:currentFrame.viewICBData[0]
                  frameViewData:currentFrame.viewData[0]
                      onEncoder:forwardEncoder
                     renderMode:_config.renderMode
                         passes:@[@(AAPLRenderPassForward),@(AAPLRenderPassForwardAlphaMasked)]
                          flags:nil
                     equalDepth:useEqualDepth];
            }

            [forwardEncoder setTriangleFillMode:MTLTriangleFillModeFill];

            if(_config.lightingMode == AAPLLightingModeForward)
            {
                // only render sky if fully forward
                [self drawSky:currentFrame.viewData[0] onEncoder:forwardEncoder];
            }

            if(_showWireframe)
                [forwardEncoder setTriangleFillMode:MTLTriangleFillModeLines];

            // render transparent after sky so they correctly blend
            [self drawScene:currentFrame.viewICBData[0]
              frameViewData:currentFrame.viewData[0]
                  onEncoder:forwardEncoder
                 renderMode:_config.renderMode
                     passes:@[@(AAPLRenderPassForwardTransparent)]
                      flags:nil
                 equalDepth:NO];

            [forwardEncoder endEncoding];
        }

        // -----------------------------------------------------------
        // PostFX
        // -----------------------------------------------------------

        id<MTLTexture> resolveTarget = _mainView ? _mainView : getViewRenderPassDescriptor().colorAttachments[0].texture;

#if USE_RESOLVE_PASS
        _resolvePassDescriptor.colorAttachments[0].texture = resolveTarget;

        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_resolvePassDescriptor];
        renderEncoder.label = @"ResolvePassEncoder";

        [renderEncoder setRenderPipelineState:_resolvePipelineState];

        [renderEncoder setFragmentBuffer:frameDataBuffer offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setFragmentBuffer:currentFrame.viewData[0].cameraParamsBuffer offset:0 atIndex:AAPLBufferIndexCameraParams];

#if SUPPORT_RASTERIZATION_RATE
        [renderEncoder setFragmentBuffer:_rrMapData offset:0 atIndex:AAPLBufferIndexRasterizationRateMap];
#endif

        id<MTLTexture> history = _history;

        if(_resetHistory)
            history = _lightingBuffer;

        [renderEncoder setFragmentTexture:_lightingBuffer atIndex:0];
        [renderEncoder setFragmentTexture:history atIndex:1];
        [renderEncoder setFragmentTexture:_depthTexture atIndex:2];
        [renderEncoder setFragmentTexture:_perlinNoiseTexture atIndex:3];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        [renderEncoder endEncoding];

#if SUPPORT_TEMPORAL_ANTIALIASING
        if(_config.useTemporalAA)
        {
            // copy history
            id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
            blitEncoder.label = @"CopyHistoryEncoder";

            MTLOrigin srcOrigin = MTLOriginMake(0, 0, 0);
            MTLSize srcSize = MTLSizeMake(_history.width, _history.height, 1);

            [blitEncoder copyFromTexture:resolveTarget sourceSlice:0 sourceLevel:0 sourceOrigin:srcOrigin sourceSize:srcSize
                               toTexture:_history destinationSlice:0 destinationLevel:0 destinationOrigin:srcOrigin];

            [blitEncoder endEncoding];
        }
#endif
#endif // USE_RESOLVE_PASS

#if ENABLE_DEBUG_RENDERING
        [self renderDebug:commandBuffer
                   target:resolveTarget
          frameDataBuffer:frameDataBuffer
             cameraParams:currentFrame.viewData[0].cameraParamsBuffer
           viewProjMatrix:_viewCamera.cameraParams.viewProjectionMatrix
               cullCamera:cullCamera];
#endif

        id <MTLTexture> backBuffer = getViewRenderPassDescriptor().colorAttachments[0].texture;

#if USE_VIRTUAL_JOYSTICKS
        if(_renderUI)
        {
            MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor new];
            passDescriptor.colorAttachments[0].texture      = resolveTarget;
            passDescriptor.colorAttachments[0].loadAction   = MTLLoadActionLoad;
            passDescriptor.colorAttachments[0].storeAction  = MTLStoreActionStore;

            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
            renderEncoder.label = @"UI";

            [renderEncoder setRenderPipelineState:_simple2DPipelineState];
            [renderEncoder setDepthStencilState:_depthStateAlwaysNoWrite];

            // draw virtual joysticks
            constexpr simd::float4 white = (simd::float4){ 1.0f, 1.0f, 1.0f, 1.0f };
            for(int i = 0; i < NUM_VIRTUAL_JOYSTICKS; ++i)
            {
                const float4x4 mat = _joystickMatrices[i];

                [renderEncoder setVertexBytes:&mat length:sizeof(mat) atIndex:AAPLBufferIndexCameraParams];
                [renderEncoder setVertexBuffer:_circleVB offset:0 atIndex:AAPLBufferIndexVertexMeshPositions];
                [renderEncoder setFragmentBytes:&white length:sizeof(white) atIndex:AAPLBufferIndexFragmentMaterial];

                [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                          indexCount:_circleIB.length / sizeof(uint16_t)
                                           indexType:MTLIndexTypeUInt16
                                         indexBuffer:_circleIB
                                   indexBufferOffset:0];
            }

            [renderEncoder endEncoding];
        }
#endif // USE_VIRTUAL_JOYSTICKS

        if(resolveTarget != backBuffer)
        {
            // copy resolve target to backbuffer
            MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor new];
            passDescriptor.colorAttachments[0].texture      = backBuffer;
            passDescriptor.colorAttachments[0].loadAction   = MTLLoadActionLoad;
            passDescriptor.colorAttachments[0].storeAction  = MTLStoreActionStore;

            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
            renderEncoder.label = @"CopyResolveToBackbuffer";

            [renderEncoder setDepthStencilState:_depthStateAlwaysNoWrite];
            [renderEncoder setRenderPipelineState:_resolveCopyToBackBuffer];
            [renderEncoder setFragmentTexture:resolveTarget atIndex:0];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

            [renderEncoder endEncoding];
        }

        [commandBuffer presentDrawable:view.currentDrawable];
    }

#if SUPPORT_PAGE_ACCESS_COUNTERS
    if(_textureManager.usePageAccessCounters)
        [_textureManager updateAccessCounters:_frameIndex cmdBuffer:commandBuffer];
#endif

    [commandBuffer commit];

    _firstFrame = false;
    _resetHistory = false;
}


- (void)resize:(CGSize)size
{
    // Respond to drawable size or orientation changes here
    _screenWidth    = size.width;
    _screenHeight   = size.height;

    _mainViewWidth  = size.width;
    _mainViewHeight = size.height;

#if 0 // render at half res and upscale
    _mainViewWidth  /= 2;
    _mainViewHeight /= 2;
#endif

    _viewCamera.aspectRatio = (float)_mainViewWidth / (float)_mainViewHeight;

    const bool needCustomMainView = _mainViewWidth < _screenWidth || _mainViewHeight < _screenHeight;

    if(needCustomMainView)
    {
        bool validMainViewTexture = (_mainView != nil && _mainView.width == _mainViewWidth && _mainView.height == _mainViewHeight);

        if (!validMainViewTexture)
        {
            MTLTextureDescriptor* desc =
            [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_view.colorPixelFormat
                                                               width:_mainViewWidth
                                                              height:_mainViewHeight
                                                           mipmapped:false];
            desc.storageMode    = MTLStorageModePrivate;
            desc.usage          = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
            _mainView           = [_device newTextureWithDescriptor:desc];
            _mainView.label     = @"MainViewTexture";
        }
    }
    else
    {
        _mainView = nil;
    }

    // Physical width is the dimensions of the rendering post-rasterization.
    // This can be different from the logical rendering size when rasterization rate is distorted.
    _physicalWidth = _mainViewWidth;
    _physicalHeight = _mainViewHeight;

#if SUPPORT_RASTERIZATION_RATE
    if (_config.useRasterizationRate)
    {
        if (!_rateMap || !_rrMapData || _rateMap.screenSize.width != _mainViewWidth || _rateMap.screenSize.height != _mainViewHeight)
        {
            const float quality[5] = { 0.3f, 0.6f, 1.0f, 0.6f, 0.3f };
            MTLRasterizationRateLayerDescriptor* rrLayer = [[MTLRasterizationRateLayerDescriptor alloc] initWithSampleCount:MTLSizeMake(5, 5, 0) horizontal:quality vertical:quality];
            MTLRasterizationRateMapDescriptor* rrDesc = [MTLRasterizationRateMapDescriptor rasterizationRateMapDescriptorWithScreenSize:MTLSizeMake(_mainViewWidth, _mainViewHeight, 0) layer:rrLayer];
            rrDesc.label = @"Scene RasterizationRate";
            _rateMap = [_device newRasterizationRateMapWithDescriptor:rrDesc];
            _rrMapData = [_device newBufferWithLength:_rateMap.parameterBufferSizeAndAlign.size options:0];
            _rrMapData.label = @"Scene RasterizationRateMap metadata";
            [_rateMap copyParameterDataToBuffer:_rrMapData offset:0];
        }

        // Adjust the main view to be the physical size of this rendering
        // During resolve, we will upscale this again
        _physicalWidth = (uint32_t)[_rateMap physicalSizeForLayer:0].width;
        _physicalHeight = (uint32_t)[_rateMap physicalSizeForLayer:0].height;
    }
#endif

    bool validDepthTexture = (_depthTexture != nil &&
                              _depthTexture.width == _physicalWidth &&
                              _depthTexture.height == _physicalHeight);

    if (!validDepthTexture)
    {
        MTLTextureDescriptor* depthTexDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:DepthStencilFormat
                                                           width:_physicalWidth
                                                          height:_physicalHeight
                                                       mipmapped:false];
        depthTexDesc.storageMode    = MTLStorageModePrivate;
        depthTexDesc.usage          = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        _depthTexture               = [_device newTextureWithDescriptor:depthTexDesc];
        _depthTexture.label         = @"DepthTexture";

#if SUPPORT_DEPTH_PREPASS_TILE_SHADERS || SUPPORT_LIGHT_CULLING_TILE_SHADERS
        if(_config.useDepthPrepassTileShaders || _config.useLightCullingTileShaders)
        {
            depthTexDesc.pixelFormat        = MTLPixelFormatR32Float;
            depthTexDesc.storageMode        = MTLStorageModeMemoryless;
            _depthImageblockTexture         = [_device newTextureWithDescriptor:depthTexDesc];
            _depthImageblockTexture.label   = @"DepthImageblockTexture";
        }
#endif
    }

    if (![AAPLDepthPyramid isPyramidTextureValidForDepth:_depthPyramidTexture
                                            depthTexture:_depthTexture])
    {
        _depthPyramidTexture = [AAPLDepthPyramid allocatePyramidTextureFromDepth:_depthTexture
                                                                          device:_device];
        _depthPyramidTexture.label  = @"DepthPyramid";

        [_globalTexturesEncoder setTexture:_depthPyramidTexture atIndex:AAPLGlobalTextureIndexViewDepthPyramid];
    }

#if USE_SCALABLE_AMBIENT_OBSCURANCE
    [_ambientObscurance resize:CGSizeMake(_physicalWidth, _physicalHeight)];
    [_globalTexturesEncoder setTexture:_ambientObscurance.texture atIndex:AAPLGlobalTextureIndexSAO];

    if (![AAPLDepthPyramid isPyramidTextureValidForDepth:_saoMippedDepth
                                            depthTexture:_depthTexture])
    {
        _saoMippedDepth = [AAPLDepthPyramid allocatePyramidTextureFromDepth:_depthTexture
                                                                     device:_device];
        _saoMippedDepth.label = @"SAOMippedDepth";
    }
#endif

    bool validGBuffer = (_gBufferTextures[AAPLTraditionalGBufferStart] != nil &&
                         _gBufferTextures[AAPLTraditionalGBufferStart].width == _physicalWidth &&
                         _gBufferTextures[AAPLTraditionalGBufferStart].height == _physicalHeight);

    if (!validGBuffer)
    {
        MTLTextureDescriptor* gbufferTexDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatInvalid
                                                           width:_physicalWidth
                                                          height:_physicalHeight
                                                       mipmapped:false];

        gbufferTexDesc.storageMode = MTLStorageModePrivate;
        gbufferTexDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

#if SUPPORT_SINGLE_PASS_DEFERRED
        if(_config.singlePassDeferredLighting)
        {
            gbufferTexDesc.storageMode = MTLStorageModeMemoryless;
        }
#endif

        for (uint GBufferIndex = AAPLTraditionalGBufferStart; GBufferIndex < AAPLGBufferIndexCount; GBufferIndex++)
        {
            gbufferTexDesc.pixelFormat = GBufferPixelFormats[GBufferIndex];
            _gBufferTextures[GBufferIndex] = [_device newTextureWithDescriptor:gbufferTexDesc];

            _gBufferPassDescriptor.colorAttachments[GBufferIndex].texture = _gBufferTextures[GBufferIndex];
        }

        _gBufferTextures[AAPLGBufferAlbedoAlphaIndex].label = @"Albedo/Alpha";
        _gBufferTextures[AAPLGBufferNormalsIndex].label     = @"Normals";
        _gBufferTextures[AAPLGBufferEmissiveIndex].label    = @"Emissive";
        _gBufferTextures[AAPLGBufferF0RoughnessIndex].label = @"F0/Roughnes";

    }

    _culledLights = [_lightCuller createResultInstance:MTLSizeMake(_physicalWidth, _physicalHeight, 1) lightCount:[self getMaxLightCount]];

    bool validLightingBuffer = _lightingBuffer != nil && (_lightingBuffer.width == _physicalWidth) && (_lightingBuffer.height == _physicalHeight);

    if (!validLightingBuffer)
    {
        MTLTextureDescriptor* desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:LightingPixelFormat
                                                           width:_physicalWidth
                                                          height:_physicalHeight
                                                       mipmapped:false];

        desc.storageMode = MTLStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

        _lightingBuffer = [_device newTextureWithDescriptor:desc];
        _lightingBuffer.label = @"Lighting Buffer";

#if SUPPORT_SINGLE_PASS_DEFERRED
        if(_config.singlePassDeferredLighting)
        {
            _gBufferTextures[AAPLGBufferLightIndex] = _lightingBuffer;
            _gBufferPassDescriptor.colorAttachments[AAPLGBufferLightIndex].texture = _lightingBuffer;
        }
#endif

        _lightingPassDescriptor.colorAttachments[0].texture = _lightingBuffer;
    }

#if USE_SCATTERING_VOLUME
    [_scatterVolume resize:CGSizeMake(_physicalWidth, _physicalHeight)];
    [_globalTexturesEncoder setTexture:_scatterVolume.scatteringAccumVolume atIndex:AAPLGlobalTextureIndexScattering];
#endif

    bool validHistory = _history != nil && (_history.width == _mainViewWidth) && (_history.height == _mainViewHeight);

    if (!validHistory)
    {
        MTLTextureDescriptor* desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:HistoryPixelFormat
                                                           width:_mainViewWidth
                                                          height:_mainViewHeight
                                                       mipmapped:false];

        desc.storageMode = MTLStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

        _history = [_device newTextureWithDescriptor:desc];

        _history.label = @"History";
    }

    _resetHistory = true;
}

// Toggles the camera animation
- (void)toggleCameraPlayback
{
    if(_cullingVisualizationMode == AAPLVisualizationTypeNone || _cullingVisualizationMode == AAPLVisualizationTypeChunkIndex)
    {
        _cameraController.enabled = !_cameraController.enabled;
        _secondaryCameraController.enabled = false;
    }
    else
    {
        _secondaryCameraController.enabled = !_secondaryCameraController.enabled;
        _cameraController.enabled = false;
    }
}

// Toggles the freezing of culling.
- (void)toggleFrozenCulling
{
    _cullingVisualizationMode = (_cullingVisualizationMode + 1) % AAPLVisualizationTypeCount;

#if SUPPORT_ON_SCREEN_SETTINGS
    if(_cullingVisualizationModeDebug == 2)
        _cullingVisualizationMode = AAPLVisualizationTypeFrustumCullOcclusionCull;
    else
        _cullingVisualizationMode = _cullingVisualizationModeDebug;
#endif

    _syncSecondaryCamera = _cullingVisualizationMode == AAPLVisualizationTypeNone || _cullingVisualizationMode ==  AAPLVisualizationTypeChunkIndex;
}

#if SUPPORT_ON_SCREEN_SETTINGS
- (void)registerWidgets:(AAPLSettingsTableViewController*)settingsController
{
    [settingsController addCombo:@"Culling Mode" options:@[@"None",@"Frustum",@"Frustum+Occlusion"] value:(uint*)&_cullTypeDebug callback:nil];
    //[settingsController addToggle:@"Merge Chunks" value:&_mergeChunks];
    [settingsController addCombo:@"Chunk Visualization Mode" options:@[@"None",@"Chunk Index",@"Chunk Culling"] value:&_cullingVisualizationModeDebug callback:^()
    {
        [self toggleFrozenCulling];
    }];

    [settingsController addToggle:@"Wireframe" value:&_showWireframe callback:nil];
    [settingsController addToggle:@"Debug Draw Occluders" value:&_debugDrawOccluders callback:nil];

    [settingsController addCombo:@"Light Culling Visualization" options:@[@"None",@"Tile",@"Cluster"] value:&_lightHeatmapMode callback:nil];
    [settingsController addToggle:@"Debug Draw Lights" value:&_showLights callback:nil];

    [settingsController addButton:@"Toggle Camera Animation" callback:^()
    {
        [self toggleCameraPlayback];
    }];

    [settingsController addSlider:@"Time of Day" value:&_timeOfDayDebug min:0.0f max:(_lightingEnvironment.count - 1.0f)];
    [settingsController addSlider:@"Fog density" value:&_scatterScaleDebug min:0.0f max:7.0f];
    [settingsController addSlider:@"Exposure" value:&_exposureScaleDebug min:0.1f max:4.0f];

    [settingsController addToggle:@"Draw UI" value:&_renderUI callback:nil];

#if SUPPORT_RASTERIZATION_RATE
    if (_config.useRasterizationRate)
    {
        [settingsController addToggle:@"Use RRMap for scene" value:&_config.useRasterizationRate callback:^()
        {
            [self->_lastCommandBuffer waitUntilCompleted];
            [self resetForCurrentConfigWithView:self->_view library:[self->_device newDefaultLibrary]];
            [self resize:CGSizeMake(self->_screenWidth, self->_screenHeight)];
        }];
    }
#endif // SUPPORT_RASTERIZATION_RATE
}
#endif // SUPPORT_ON_SCREEN_SETTINGS

@end

