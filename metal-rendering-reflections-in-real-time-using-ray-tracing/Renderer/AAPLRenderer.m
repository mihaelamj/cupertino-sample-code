/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implemenation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <ModelIO/ModelIO.h>
#import "AAPLMathUtilities.h"

#import "AAPLRenderer.h"

#import "AAPLMesh.h"
#import "AAPLModelInstance.h"

/// Include the headers that share types between the C code here, which executes
/// Metal API commands, and the .metal files, which use the types as inputs to the shaders.
#import "AAPLShaderTypes.h"
#import "AAPLArgumentBufferTypes.h"

/// Controls whether to include Metal residency set functionality to the app.
/// The `MTLResidencySet` APIs require macOS 15 or later, or iOS 18 or later.
#if (TARGET_MACOS && defined(__MAC_15_0) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_15_0)) || \
    (TARGET_IOS && defined(__IPHONE_18_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_18_0))
    #define AAPL_SUPPORTS_RESIDENCY_SETS 1
#else
    #define AAPL_SUPPORTS_RESIDENCY_SETS 0
#endif

MTLPackedFloat4x3 matrix4x4_drop_last_row(matrix_float4x4 m)
{
    return (MTLPackedFloat4x3){
        MTLPackedFloat3Make( m.columns[0].x, m.columns[0].y, m.columns[0].z ),
        MTLPackedFloat3Make( m.columns[1].x, m.columns[1].y, m.columns[1].z ),
        MTLPackedFloat3Make( m.columns[2].x, m.columns[2].y, m.columns[2].z ),
        MTLPackedFloat3Make( m.columns[3].x, m.columns[3].y, m.columns[3].z )
    };
}

static const NSUInteger kMaxBuffersInFlight = 3;

static const size_t kAlignedInstanceTransformsStructSize = (sizeof(AAPLInstanceTransform) & ~0xFF) + 0x100;

typedef enum AccelerationStructureEvents : uint64_t
{
    kPrimitiveAccelerationStructureBuild = 1,
    kInstanceAccelerationStructureBuild = 2
} AccelerationStructureEvents;

typedef struct ThinGBuffer
{
    id<MTLTexture> positionTexture;
    id<MTLTexture> directionTexture;
} ThinGBuffer;

/// A helper function that passes an array of instances into batch methods that require pointers and counts.
void arrayToBatchMethodHelper(NSArray *array, void (^callback)(__unsafe_unretained id *, NSUInteger))
{
    static const NSUInteger bufferLength = 16;
    __unsafe_unretained id buffer[bufferLength];
    NSFastEnumerationState state = {};

    NSUInteger count;

    while ((count = [array countByEnumeratingWithState:&state objects:buffer count:bufferLength]) > 0)
    {
        callback(state.itemsPtr, count);
    }
}

@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;

    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    id<MTLBuffer> _lightDataBuffer;
    id<MTLBuffer> _cameraDataBuffers[kMaxBuffersInFlight];
    id<MTLBuffer> _instanceTransformBuffer;

    id<MTLRenderPipelineState> _pipelineState;
    id<MTLRenderPipelineState> _pipelineStateNoRT;
    id<MTLRenderPipelineState> _pipelineStateReflOnly;
    id<MTLRenderPipelineState> _gbufferPipelineState;
    id<MTLRenderPipelineState> _skyboxPipelineState;
    id<MTLDepthStencilState> _depthState;

    MTLVertexDescriptor *_mtlVertexDescriptor;
    MTLVertexDescriptor *_mtlSkyboxVertexDescriptor;

    uint8_t _cameraBufferIndex;
    matrix_float4x4 _projectionMatrix;

    NSArray< AAPLMesh* >* _meshes;
    AAPLMesh* _skybox;
    id<MTLTexture> _skyMap;

    ModelInstance _modelInstances[kMaxModelInstances];
    id<MTLEvent> _accelerationStructureBuildEvent;
    id<MTLAccelerationStructure> _instanceAccelerationStructure;

    id<MTLTexture> _rtReflectionMap;
    id<MTLFunction> _rtReflectionFunction;
    id<MTLComputePipelineState> _rtReflectionPipeline;
    id<MTLHeap> _rtMipmappingHeap;
    id<MTLRenderPipelineState> _rtMipmapPipeline;

    /// Postprocessing pipelines.
    id<MTLRenderPipelineState> _bloomThresholdPipeline;
    id<MTLRenderPipelineState> _postMergePipeline;
    id<MTLTexture> _rawColorMap;
    id<MTLTexture> _bloomThresholdMap;
    id<MTLTexture> _bloomBlurMap;

    ThinGBuffer _thinGBuffer;

    /// The argument buffer that contains the resources and constants required for rendering.
    id<MTLBuffer> _sceneArgumentBuffer;

    NSMutableArray<id<MTLResource>>* _sceneResources;
    NSMutableArray<id<MTLHeap>>* _sceneHeaps;

#if AAPL_SUPPORTS_RESIDENCY_SETS
    NS_AVAILABLE(15, 18)
    id<MTLResidencySet> _sceneResidencySet;
    BOOL _useResidencySet;
#endif

    float _cameraAngle;
    float _cameraPanSpeedFactor;
    float _metallicBias;
    float _roughnessBias;
    float _exposure;
    RenderMode _renderMode;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view size:(CGSize)size
{
    self = [super init];
    if (self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        _accelerationStructureBuildEvent = [_device newEvent];
        configureModelInstances(_modelInstances, kMaxModelInstances);
        _projectionMatrix = [self projectionMatrixWithAspect:size.width / size.height];
        _sceneResources = [[NSMutableArray alloc] init];
        _sceneHeaps = [[NSMutableArray alloc] init];
        [self loadMetalWithView:view];
        [self loadAssets];

        BOOL createdArgumentBuffers = NO;

        char* opts = getenv("DISABLE_METAL3_FEATURES");
        if ((opts == NULL) || (strstr(opts, "1") != opts))
        {
            if ( @available( macOS 13, iOS 16, *) )
            {
                if ( [_device supportsFamily:MTLGPUFamilyMetal3] )
                {
                    createdArgumentBuffers = YES;
                    [self buildSceneArgumentBufferMetal3];
                }
            }
        }

        if (!createdArgumentBuffers)
        {
            [self buildSceneArgumentBufferFromReflectionFunction:_rtReflectionFunction];
        }

        // Call this last to ensure everything else builds.
        [self resizeRTReflectionMapTo:view.drawableSize];
        [self buildRTAccelerationStructures];

#if AAPL_SUPPORTS_RESIDENCY_SETS
        if ((opts == NULL) || (strstr(opts, "1") != opts))
        {
            if ( @available( macOS 15, iOS 18, *) )
            {
                if ( [_device supportsFamily:MTLGPUFamilyApple6] )
                {
                    [self buildSceneResidencySet];
                    _useResidencySet = YES;
                }
            }
        }
#endif

        _cameraPanSpeedFactor = 0.5f;
        _metallicBias = 0.0f;
        _roughnessBias = 0.0f;
        _exposure = 1.0f;

    }

    return self;
}

- (void)resizeRTReflectionMapTo:(CGSize)size
{
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRG11B10Float
                                                                                    width:size.width
                                                                                   height:size.height
                                                                                mipmapped:YES];
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
    _rtReflectionMap = [_device newTextureWithDescriptor:desc];

    desc.mipmapLevelCount = 1;
    _rawColorMap = [_device newTextureWithDescriptor:desc];
    _bloomThresholdMap = [_device newTextureWithDescriptor:desc];
    _bloomBlurMap = [_device newTextureWithDescriptor:desc];

    desc.pixelFormat = MTLPixelFormatRGBA16Float;
    desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
    desc.mipmapLevelCount = 1;
    _thinGBuffer.positionTexture = [_device newTextureWithDescriptor:desc];
    _thinGBuffer.directionTexture = [_device newTextureWithDescriptor:desc];

    MTLHeapDescriptor* hd = [[MTLHeapDescriptor alloc] init];
    hd.size = size.width * size.height * 4 * 2 * 3;
    hd.storageMode = MTLStorageModePrivate;
    _rtMipmappingHeap = [_device newHeapWithDescriptor:hd];
}

#pragma mark - Build Pipeline States

/// Load the Metal state objects and initialize the renderer-dependent view properties.
- (void)loadMetalWithView:(nonnull MTKView *)view;
{
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    // Positions.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

    // Texture coordinates.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Normals.
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 8;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Tangents
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].offset = 16;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Bitangents
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].format = MTLVertexFormatHalf4;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].offset = 24;
    _mtlVertexDescriptor.attributes[AAPLVertexAttributeBitangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Position Buffer Layout
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Generic Attribute Buffer Layout
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 32;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
    _mtlVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;
    
    _mtlSkyboxVertexDescriptor = [[MTLVertexDescriptor alloc] init];
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
    _mtlSkyboxVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = sizeof(simd_float2);
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
    _mtlSkyboxVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = MTLVertexStepFunctionPerVertex;

    NSError* error;
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    {
        id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

        MTLFunctionConstantValues* functionConstants = [MTLFunctionConstantValues new];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];

        {
            BOOL enableRaytracing = YES;
            [functionConstants setConstantValue:&enableRaytracing type:MTLDataTypeBool atIndex:AAPLConstantIndexRayTracingEnabled];
            id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader" constantValues:functionConstants error:nil];

            pipelineStateDescriptor.label = @"RT Pipeline";
            pipelineStateDescriptor.rasterSampleCount = view.sampleCount;
            pipelineStateDescriptor.vertexFunction = vertexFunction;
            pipelineStateDescriptor.fragmentFunction = fragmentFunction;
            pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRG11B10Float; //view.colorPixelFormat;
            pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
            pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

            _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        }

        {
            BOOL enableRaytracing = NO;
            [functionConstants setConstantValue:&enableRaytracing type:MTLDataTypeBool atIndex:AAPLConstantIndexRayTracingEnabled];
            id<MTLFunction> fragmentFunctionNoRT = [defaultLibrary newFunctionWithName:@"fragmentShader" constantValues:functionConstants error:nil];

            pipelineStateDescriptor.label = @"No RT Pipeline";
            pipelineStateDescriptor.fragmentFunction = fragmentFunctionNoRT;

            _pipelineStateNoRT = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineStateNoRT, @"Failed to create No RT pipeline state: %@", error);
        }

        {
            pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"reflectionShader"];
            pipelineStateDescriptor.label = @"Reflection Viewer Pipeline";

            _pipelineStateReflOnly = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_pipelineStateNoRT, @"Failed to create Reflection Viewer pipeline state: %@", error);
        }

        {
            id<MTLFunction> gBufferFragmentFunction = [defaultLibrary newFunctionWithName:@"gBufferFragmentShader"];
            pipelineStateDescriptor.label = @"ThinGBufferPipeline";
            pipelineStateDescriptor.fragmentFunction = gBufferFragmentFunction;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatRGBA16Float;

            _gbufferPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_gbufferPipelineState, @"Failed to create GBuffer pipeline state: %@", error);
        }

        {
            id<MTLFunction> skyboxVertexFunction = [defaultLibrary newFunctionWithName:@"skyboxVertex"];
            id<MTLFunction> skyboxFragmentFunction = [defaultLibrary newFunctionWithName:@"skyboxFragment"];
            pipelineStateDescriptor.label = @"SkyboxPipeline";
            pipelineStateDescriptor.vertexDescriptor = _mtlSkyboxVertexDescriptor;
            pipelineStateDescriptor.vertexFunction = skyboxVertexFunction;
            pipelineStateDescriptor.fragmentFunction = skyboxFragmentFunction;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRG11B10Float; //MTLPixelFormatBGRA8Unorm_sRGB;
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatInvalid;

             _skyboxPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
            NSAssert(_skyboxPipelineState, @"Failed to create Skybox Render Pipeline State: %@", error );
        }
    }

    if (_device.supportsRaytracing)
    {
        _rtReflectionFunction = [defaultLibrary newFunctionWithName:@"rtReflection"];

        _rtReflectionPipeline = [_device newComputePipelineStateWithFunction:_rtReflectionFunction error:&error];
        NSAssert(_rtReflectionPipeline, @"Failed to create RT reflection compute pipeline state: %@", error);

        _renderMode = RMMetalRaytracing;
    }
    else
    {
        _renderMode = RMNoRaytracing;
    }
    
    {
        id< MTLFunction > passthroughVert = [defaultLibrary newFunctionWithName:@"vertexPassthrough" ];
        id< MTLFunction > fragmentFn = [defaultLibrary newFunctionWithName:@"fragmentPassthrough"];
        MTLRenderPipelineDescriptor* passthroughDesc = [[MTLRenderPipelineDescriptor alloc] init];
        passthroughDesc.vertexFunction = passthroughVert;
        passthroughDesc.fragmentFunction = fragmentFn;
        passthroughDesc.colorAttachments[0].pixelFormat = MTLPixelFormatRG11B10Float;

        NSError* __autoreleasing error = nil;
        _rtMipmapPipeline = [_device newRenderPipelineStateWithDescriptor:passthroughDesc error:&error];
        NSAssert( _rtMipmapPipeline, @"Error creating passthrough pipeline: %@", error.localizedDescription );

        fragmentFn = [defaultLibrary newFunctionWithName:@"fragmentBloomThreshold"];
        passthroughDesc.fragmentFunction = fragmentFn;
        passthroughDesc.colorAttachments[0].pixelFormat = MTLPixelFormatRG11B10Float;
        _bloomThresholdPipeline = [_device newRenderPipelineStateWithDescriptor:passthroughDesc error:&error];
        NSAssert( _bloomThresholdPipeline, @"Error creating bloom threshold pipeline: %@", error.localizedDescription );

        fragmentFn = [defaultLibrary newFunctionWithName:@"fragmentPostprocessMerge"];
        passthroughDesc.fragmentFunction = fragmentFn;
        passthroughDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
        _postMergePipeline = [_device newRenderPipelineStateWithDescriptor:passthroughDesc error:&error];
        NSAssert( _postMergePipeline, @"Error creating postprocessing merge pass: %@", error.localizedDescription);
    }

    {
        MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;

        _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    for (int i = 0; i < kMaxBuffersInFlight; i++)
    {
        _cameraDataBuffers[i] = [_device newBufferWithLength:sizeof(AAPLCameraData)
                                                 options:MTLResourceStorageModeShared];

        _cameraDataBuffers[i].label = [NSString stringWithFormat:@"CameraDataBuffer %d", i];
    }

    NSUInteger instanceBufferSize = kAlignedInstanceTransformsStructSize * kMaxModelInstances;
    _instanceTransformBuffer = [_device newBufferWithLength:instanceBufferSize
                                                    options:MTLResourceStorageModeShared];
    _instanceTransformBuffer.label = @"InstanceTransformBuffer";

    _lightDataBuffer = [_device newBufferWithLength:sizeof(AAPLLightData) options:MTLResourceStorageModeShared];
    _lightDataBuffer.label = @"LightDataBuffer";

    _commandQueue = [_device newCommandQueue];

    [self setStaticState];
}

#pragma mark - Asset Loading

/// Create and load assets into Metal objects, including meshes and textures.
- (void)loadAssets
{
    NSError *error;

    // Create a Model I/O vertexDescriptor to format the Model I/O mesh vertices to
    // fit the Metal render pipeline's vertex descriptor layout.
    MDLVertexDescriptor *modelIOVertexDescriptor =
        MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);

    // Indicate the Metal vertex descriptor attribute mapping for each Model I/O attribute.
    modelIOVertexDescriptor.attributes[AAPLVertexAttributePosition].name  = MDLVertexAttributePosition;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeNormal].name    = MDLVertexAttributeNormal;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTangent].name   = MDLVertexAttributeTangent;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeBitangent].name = MDLVertexAttributeBitangent;

    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:@"Models/firetruck.obj"
                                                  withExtension:nil];

    NSAssert(modelFileURL, @"Could not find model (%@) file in bundle creating specular texture", modelFileURL.absoluteString);

    NSMutableArray< AAPLMesh* >* scene = [[NSMutableArray alloc] init];
    [scene addObjectsFromArray:[AAPLMesh newMeshesFromURL:modelFileURL
                                           modelIOVertexDescriptor:modelIOVertexDescriptor
                                                       metalDevice:_device
                                                             error:&error]];

    [scene addObject:[AAPLMesh newSphereWithRadius:8.0f onDevice:_device vertexDescriptor:modelIOVertexDescriptor]];

    [scene addObject:[AAPLMesh newPlaneWithDimensions:(vector_float2){200.0f, 200.0f} onDevice:_device vertexDescriptor:modelIOVertexDescriptor]];

    _meshes = scene;

    NSAssert(_meshes, @"Could not create meshes from model file %@: %@", modelFileURL.absoluteString, error);

    _skyMap = texture_from_radiance_file( @"kloppenheim_06_4k.hdr", _device, &error );
    NSAssert( _skyMap, @"Could not load sky texture: %@", error );

    MDLVertexDescriptor *skyboxModelIOVertexDescriptor =
        MTKModelIOVertexDescriptorFromMetal(_mtlSkyboxVertexDescriptor);
    skyboxModelIOVertexDescriptor.attributes[VertexAttributePosition].name = MDLVertexAttributePosition;
    skyboxModelIOVertexDescriptor.attributes[VertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;

    _skybox = [AAPLMesh newSkyboxMeshOnDevice:_device vertexDescriptor:skyboxModelIOVertexDescriptor];
    NSAssert( _skybox, @"Could not create skybox model" );
}

#pragma mark - Encode Argument Buffers

/// A convenience method to create `MTLArgumentDescriptor` objects for read-only access.
- (MTLArgumentDescriptor *)argumentDescriptorWithIndex:(NSUInteger)index dataType:(MTLDataType)dataType
{
    MTLArgumentDescriptor* argumentDescriptor = [MTLArgumentDescriptor argumentDescriptor];
    argumentDescriptor.index = index;
    argumentDescriptor.dataType = dataType;
    argumentDescriptor.access = MTLArgumentAccessReadOnly;
    return argumentDescriptor;
}

/// Build an argument buffer with all the  resources for the scene.   The ray-tracing shaders access meshes, submeshes, and materials
/// through this argument buffer to apply the correct lighting to the calculated reflections.
- (void)buildSceneArgumentBufferFromReflectionFunction:(nonnull id<MTLFunction>)function
{
    MTLResourceOptions storageMode;
#if TARGET_MACOS
    storageMode = MTLResourceStorageModeManaged;
#else
    storageMode = MTLResourceStorageModeShared;
#endif

    // Create argument buffer encoders from the scene argument of the ray-tracing reflection function.
    id<MTLArgumentEncoder> sceneEncoder =
        [function newArgumentEncoderWithBufferIndex:SceneIndex];

    id<MTLArgumentEncoder> instanceEncoder =
        [sceneEncoder newArgumentEncoderForBufferAtIndex:AAPLArgmentBufferIDSceneInstances];

    id<MTLArgumentEncoder> meshEncoder =
        [sceneEncoder newArgumentEncoderForBufferAtIndex:AAPLArgumentBufferIDSceneMeshes];

    id<MTLArgumentEncoder> submeshEncoder =
        [meshEncoder newArgumentEncoderForBufferAtIndex:AAPLArgmentBufferIDMeshSubmeshes];

    // The renderer builds this structure to match the ray-traced scene structure so the
    // ray-tracing shader navigates it. In particular, Metal represents each submesh as a
    // geometry in the primitive acceleration structure.
    NSUInteger instanceArgumentSize = instanceEncoder.encodedLength * kMaxModelInstances;
    id<MTLBuffer> instanceArgumentBuffer = [self newBufferWithLabel:@"instanceArgumentBuffer"
                                                             length:instanceArgumentSize
                                                            options:storageMode];

    // Encode the instances array in `Scene` (`Scene::instances`).
    for ( NSUInteger i = 0; i < kMaxModelInstances; ++i )
    {
        [instanceEncoder setArgumentBuffer:instanceArgumentBuffer offset:i * instanceEncoder.encodedLength];

        typedef struct {
            uint32_t meshIndex;
            matrix_float4x4 transform;
        } InstanceData;

        InstanceData* pInstanceData = (InstanceData *)[instanceEncoder constantDataAtIndex:0];
        pInstanceData->meshIndex = _modelInstances[i].meshIndex;
        pInstanceData->transform = calculateTransform(_modelInstances[i]);
    }

#if TARGET_MACOS
    [instanceArgumentBuffer didModifyRange:NSMakeRange(0, instanceArgumentBuffer.length)];
#endif

    NSUInteger meshArgumentSize = meshEncoder.encodedLength * _meshes.count;
    id<MTLBuffer> meshArgumentBuffer = [self newBufferWithLabel:@"meshArgumentBuffer"
                                                         length:meshArgumentSize
                                                        options:storageMode];

    // Encode the meshes array in `Scene` (`Scene::meshes`).
    for ( NSUInteger i = 0; i < _meshes.count; ++i )
    {
        AAPLMesh* mesh = _meshes[i];
        [meshEncoder setArgumentBuffer:meshArgumentBuffer offset:i * meshEncoder.encodedLength];

        MTKMesh* metalKitMesh = mesh.metalKitMesh;

        // Set `Mesh::positions`.
        [meshEncoder setBuffer:metalKitMesh.vertexBuffers[0].buffer
                        offset:metalKitMesh.vertexBuffers[0].offset
                       atIndex:AAPLArgmentBufferIDMeshPositions];

        // Set `Mesh::generics`.
        [meshEncoder setBuffer:metalKitMesh.vertexBuffers[1].buffer
                        offset:metalKitMesh.vertexBuffers[1].offset
                       atIndex:AAPLArgmentBufferIDMeshGenerics];

        NSAssert( metalKitMesh.vertexBuffers.count == 2, @"unknown number of buffers!" );

        [_sceneResources addObject:metalKitMesh.vertexBuffers[0].buffer];
        [_sceneResources addObject:metalKitMesh.vertexBuffers[1].buffer];

        // Build submeshes into a buffer and reference it through a pointer in the mesh.

        NSUInteger submeshArgumentSize = submeshEncoder.encodedLength * mesh.submeshes.count;
        id<MTLBuffer> submeshArgumentBuffer = [self newBufferWithLabel:[NSString stringWithFormat:@"submeshArgumentBuffer %lu", (unsigned long)i]
                                                                length:submeshArgumentSize
                                                               options:storageMode];

        for ( NSUInteger j = 0; j < mesh.submeshes.count; ++j )
        {
            AAPLSubmesh* submesh = mesh.submeshes[j];
            [submeshEncoder setArgumentBuffer:submeshArgumentBuffer
                                       offset:(submeshEncoder.encodedLength * j)];

            // Set `Submesh::indices`.
            MTKMeshBuffer* indexBuffer = submesh.metalKitSubmesh.indexBuffer;
            uint32_t* pIndexType = [submeshEncoder constantDataAtIndex:0];

            // Encode whether each index is 16-bit or 32-bit wide.
            *pIndexType = submesh.metalKitSubmesh.indexType == MTLIndexTypeUInt32 ? 0 : 1;

            [submeshEncoder setBuffer:indexBuffer.buffer
                               offset:indexBuffer.offset
                              atIndex:AAPLArgmentBufferIDSubmeshIndices];

            for (NSUInteger m = 0; m < submesh.textures.count; ++m)
            {
                [submeshEncoder setTexture:submesh.textures[m]
                                   atIndex:AAPLArgmentBufferIDSubmeshMaterials + m];
            }

            id<MTLBuffer> submeshIndexBuffer = submesh.metalKitSubmesh.indexBuffer.buffer;

            [_sceneResources addObject:submeshIndexBuffer];
            [_sceneResources addObjectsFromArray:submesh.textures];
        }

#if TARGET_MACOS
        [submeshArgumentBuffer didModifyRange:NSMakeRange(0, submeshArgumentBuffer.length)];
#endif

        // Set `Mesh::submeshes`.
        [meshEncoder setBuffer:submeshArgumentBuffer
                        offset:0
                       atIndex:AAPLArgmentBufferIDMeshSubmeshes];
    }

    id<MTLBuffer> sceneArgumentBuffer = [self newBufferWithLabel:@"sceneArgumentBuffer"
                                                          length:sceneEncoder.encodedLength
                                                         options:storageMode];

    [sceneEncoder setArgumentBuffer:sceneArgumentBuffer offset:0];

    // Set `Scene::instances`.
    [sceneEncoder setBuffer:instanceArgumentBuffer offset:0 atIndex:AAPLArgmentBufferIDSceneInstances];

    // Set `Scene::meshes`.
    [sceneEncoder setBuffer:meshArgumentBuffer offset:0 atIndex:AAPLArgumentBufferIDSceneMeshes];

#if TARGET_MACOS
    [meshArgumentBuffer didModifyRange:NSMakeRange(0, meshArgumentBuffer.length)];
    [sceneArgumentBuffer didModifyRange:NSMakeRange(0, sceneArgumentBuffer.length)];
#endif

    _sceneArgumentBuffer = sceneArgumentBuffer;
}

#if AAPL_SUPPORTS_RESIDENCY_SETS
- (id<MTLResidencySet>)newResidencySetWithLabel:(NSString *)label
                                          error:(NSError * __nullable * __nullable)error
NS_AVAILABLE(15, 18)
{
    MTLResidencySetDescriptor *residencySetDescriptor = [[MTLResidencySetDescriptor alloc] init];
    residencySetDescriptor.label = label;

    id<MTLResidencySet> residencySet = [_device newResidencySetWithDescriptor:residencySetDescriptor
                                                                        error:error];

    return residencySet;
}
#endif

- (id<MTLBuffer>)newBufferWithLabel:(NSString *)label length:(NSUInteger)length options:(MTLResourceOptions)options
{
    id<MTLBuffer> buffer = [_device newBufferWithLength:length options:options];
    buffer.label = label;

    [_sceneResources addObject:buffer];

    return buffer;
}

/// Build an argument buffer with all resources for the scene.   The ray-tracing shaders access meshes, submeshes,
/// and materials through this argument buffer to apply the correct lighting to the calculated reflections.
- (void)buildSceneArgumentBufferMetal3 NS_AVAILABLE(13, 16)
{
    MTLResourceOptions storageMode;
#if TARGET_MACOS
    storageMode = MTLResourceStorageModeManaged;
#else
    storageMode = MTLResourceStorageModeShared;
#endif

    // The renderer builds this structure to match the ray-traced scene structure so the
    // ray-tracing shader navigates it. In particular, Metal represents each submesh as a
    // geometry in the primitive acceleration structure.
    NSUInteger instanceArgumentSize = sizeof( struct Instance ) * kMaxModelInstances;
    id<MTLBuffer> instanceArgumentBuffer = [self newBufferWithLabel:@"instanceArgumentBuffer"
                                                             length:instanceArgumentSize
                                                             options:storageMode];

    // Encode the instances array in `Scene` (`Scene::instances`).
    for ( NSUInteger i = 0; i < kMaxModelInstances; ++i )
    {
        struct Instance* pInstance = ((struct Instance *)instanceArgumentBuffer.contents) + i;
        pInstance->meshIndex = _modelInstances[i].meshIndex;
        pInstance->transform = calculateTransform(_modelInstances[i]);
    }

#if TARGET_MACOS
    [instanceArgumentBuffer didModifyRange:NSMakeRange(0, instanceArgumentBuffer.length)];
#endif

    NSUInteger meshArgumentSize = sizeof( struct Mesh ) * _meshes.count;
    id<MTLBuffer> meshArgumentBuffer = [self newBufferWithLabel:@"meshArgumentBuffer"
                                                         length:meshArgumentSize
                                                        options:storageMode];

    // Encode the meshes array in Scene (Scene::meshes).
    for ( NSUInteger i = 0; i < _meshes.count; ++i )
    {
        AAPLMesh* mesh = _meshes[i];

        struct Mesh* pMesh = ((struct Mesh *)meshArgumentBuffer.contents) + i;

        MTKMesh* metalKitMesh = mesh.metalKitMesh;

        // Set `Mesh::positions`.
        pMesh->positions = metalKitMesh.vertexBuffers[0].buffer.gpuAddress + metalKitMesh.vertexBuffers[0].offset;

        // Set `Mesh::generics`.
        pMesh->generics = metalKitMesh.vertexBuffers[1].buffer.gpuAddress + metalKitMesh.vertexBuffers[1].offset;

        NSAssert( metalKitMesh.vertexBuffers.count == 2, @"unknown number of buffers!" );

        [_sceneResources addObject:metalKitMesh.vertexBuffers[0].buffer];
        [_sceneResources addObject:metalKitMesh.vertexBuffers[1].buffer];

        // Build submeshes into a buffer and reference it through a pointer in the mesh.

        NSUInteger submeshArgumentSize = sizeof( struct Submesh ) * mesh.submeshes.count;
        id<MTLBuffer> submeshArgumentBuffer = [self newBufferWithLabel:[NSString stringWithFormat:@"submeshArgumentBuffer %lu", (unsigned long)i]
                                                                length:submeshArgumentSize
                                                                options:storageMode];

        for ( NSUInteger j = 0; j < mesh.submeshes.count; ++j )
        {
            AAPLSubmesh* submesh = mesh.submeshes[j];
            struct Submesh* pSubmesh = ((struct Submesh *)submeshArgumentBuffer.contents) + j;

            // Set `Submesh::indices`.
            MTKMeshBuffer* indexBuffer = submesh.metalKitSubmesh.indexBuffer;
            pSubmesh->shortIndexType = submesh.metalKitSubmesh.indexType == MTLIndexTypeUInt32 ? 0 : 1;
            pSubmesh->indices = indexBuffer.buffer.gpuAddress + indexBuffer.offset;

            for (NSUInteger m = 0; m < submesh.textures.count; ++m)
            {
                pSubmesh->materials[m] = submesh.textures[m].gpuResourceID;
            }

            id<MTLBuffer> submeshIndexBuffer = submesh.metalKitSubmesh.indexBuffer.buffer;
            [_sceneResources addObject:submeshIndexBuffer];

            [_sceneResources addObjectsFromArray:submesh.textures];
        }

#if TARGET_MACOS
        [submeshArgumentBuffer didModifyRange:NSMakeRange(0, submeshArgumentBuffer.length)];
#endif

        // Set `Mesh::submeshes`.
        pMesh->submeshes = submeshArgumentBuffer.gpuAddress;
    }

    [_sceneResources addObject:meshArgumentBuffer];

    id<MTLBuffer> sceneArgumentBuffer = [self newBufferWithLabel:@"sceneArgumentBuffer"
                                                          length:sizeof( struct Scene )
                                                         options:storageMode];

    // Set `Scene::instances`.
    ((struct Scene *)sceneArgumentBuffer.contents)->instances = instanceArgumentBuffer.gpuAddress;

    // Set `Scene::meshes`.
    ((struct Scene *)sceneArgumentBuffer.contents)->meshes = meshArgumentBuffer.gpuAddress;

#if TARGET_MACOS
    [meshArgumentBuffer didModifyRange:NSMakeRange(0, meshArgumentBuffer.length)];
    [sceneArgumentBuffer didModifyRange:NSMakeRange(0, sceneArgumentBuffer.length)];
#endif

    _sceneArgumentBuffer = sceneArgumentBuffer;
    
}

#pragma mark - Build Acceleration Structures

- (id<MTLAccelerationStructure>)allocateAndBuildAccelerationStructureWithDescriptor:(MTLAccelerationStructureDescriptor *)descriptor commandBuffer:(id<MTLCommandBuffer>)cmd
{
    MTLAccelerationStructureSizes sizes = [_device accelerationStructureSizesWithDescriptor:descriptor];
    id<MTLBuffer> scratch = [_device newBufferWithLength:sizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];
    id<MTLAccelerationStructure> accelStructure = [_device newAccelerationStructureWithSize:sizes.accelerationStructureSize];

    id<MTLAccelerationStructureCommandEncoder> enc = [cmd accelerationStructureCommandEncoder];
    [enc buildAccelerationStructure:accelStructure descriptor:descriptor scratchBuffer:scratch scratchBufferOffset:0];
    [enc endEncoding];

    return accelStructure;
}

/// Calculate the minimum size needed to allocate a heap that contains all acceleration structures for the passed-in descriptors.
/// The size is the sum of the needed sizes, and the scratch and refit buffer sizes are the maximum needed.
- (MTLAccelerationStructureSizes)calculateSizeForPrimitiveAccelerationStructures:(NSArray<MTLPrimitiveAccelerationStructureDescriptor*>*)primitiveAccelerationDescriptors NS_AVAILABLE(13,16)
{
    MTLAccelerationStructureSizes totalSizes = (MTLAccelerationStructureSizes){0, 0, 0};
    for ( MTLPrimitiveAccelerationStructureDescriptor* desc in primitiveAccelerationDescriptors )
    {
        MTLSizeAndAlign sizeAndAlign = [_device heapAccelerationStructureSizeAndAlignWithDescriptor:desc];
        MTLAccelerationStructureSizes sizes = [_device accelerationStructureSizesWithDescriptor:desc];
        totalSizes.accelerationStructureSize += (sizeAndAlign.size + sizeAndAlign.align);
        totalSizes.buildScratchBufferSize = MAX( sizes.buildScratchBufferSize, totalSizes.buildScratchBufferSize );
        totalSizes.refitScratchBufferSize = MAX( sizes.refitScratchBufferSize, totalSizes.refitScratchBufferSize);
    }
    return totalSizes;
}

- (NSArray<id<MTLAccelerationStructure>> *)allocateAndBuildAccelerationStructuresWithDescriptors:(NSArray<MTLAccelerationStructureDescriptor *>*)descriptors
                                                                                            heap:(id<MTLHeap>)heap
                                                                            maxScratchBufferSize:(size_t)maxScratchSize
                                                                                     signalEvent:(id<MTLEvent>)event NS_AVAILABLE(13,16)
{
    NSAssert( heap, @"Heap argument is required" );

    NSMutableArray< id<MTLAccelerationStructure> >* accelStructures = [NSMutableArray arrayWithCapacity:descriptors.count];

    id<MTLBuffer> scratch = [_device newBufferWithLength:maxScratchSize options:MTLResourceStorageModePrivate];
    id<MTLCommandBuffer> cmd = [_commandQueue commandBuffer];
    id<MTLAccelerationStructureCommandEncoder> enc = [cmd accelerationStructureCommandEncoder];

    for ( MTLPrimitiveAccelerationStructureDescriptor* descriptor in descriptors )
    {
        MTLSizeAndAlign sizes = [_device heapAccelerationStructureSizeAndAlignWithDescriptor:descriptor];
        id<MTLAccelerationStructure> accelStructure = [heap newAccelerationStructureWithSize:sizes.size];
        [enc buildAccelerationStructure:accelStructure descriptor:descriptor scratchBuffer:scratch scratchBufferOffset:0];
        [accelStructures addObject:accelStructure];
    }

    [enc endEncoding];
    [cmd encodeSignalEvent:event value:kPrimitiveAccelerationStructureBuild];
    [cmd commit];

    return accelStructures;
}

/// Build the ray-tracing acceleration structures.
- (void)buildRTAccelerationStructures
{
    // Each mesh is an individual primitive acceleration structure, with each submesh being one
    // geometry within that acceleration structure.

    // Instance Acceleration Structure references n instances.
    // 1 Instance references 1 Primitive Acceleration Structure
    // 1 Primitive Acceleration Structure = 1 Mesh in _meshes
    // 1 Primitive Acceleration Structure -> n geometries == n submeshes

    id<MTLHeap> accelerationStructureHeap;
    NSArray< id<MTLAccelerationStructure> > *primitiveAccelerationStructures;

    NSMutableArray< MTLPrimitiveAccelerationStructureDescriptor* > *primitiveAccelerationDescriptors = [NSMutableArray arrayWithCapacity:_meshes.count];
    for ( AAPLMesh* mesh in _meshes )
    {
        NSMutableArray< MTLAccelerationStructureTriangleGeometryDescriptor* >* geometries = [NSMutableArray arrayWithCapacity:mesh.submeshes.count];
        for ( AAPLSubmesh* submesh in mesh.submeshes )
        {
            MTLAccelerationStructureTriangleGeometryDescriptor* g = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
            g.vertexBuffer = mesh.metalKitMesh.vertexBuffers.firstObject.buffer;
            g.vertexBufferOffset = mesh.metalKitMesh.vertexBuffers.firstObject.offset;
            g.vertexStride = 12; // The buffer must be packed XYZ XYZ XYZ ...

            g.indexBuffer = submesh.metalKitSubmesh.indexBuffer.buffer;
            g.indexBufferOffset = submesh.metalKitSubmesh.indexBuffer.offset;
            g.indexType = submesh.metalKitSubmesh.indexType;

            NSUInteger indexElementSize = (g.indexType == MTLIndexTypeUInt16) ? sizeof(uint16_t) : sizeof(uint32_t);
            g.triangleCount = submesh.metalKitSubmesh.indexBuffer.length / indexElementSize / 3;
            [geometries addObject:g];
        }
        MTLPrimitiveAccelerationStructureDescriptor* primDesc = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
        primDesc.geometryDescriptors = geometries;
        [primitiveAccelerationDescriptors addObject:primDesc];
    }

    // Allocate all primitive acceleration structures.
    // On Metal 3, allocate directly from a MTLHeap.
    BOOL heapBasedAllocation = NO;

    char* opts = getenv("DISABLE_METAL3_FEATURES");
    if ( (opts == NULL) || (strstr(opts, "1") != opts) )
    {
        if ( @available( macOS 13, iOS 16, *) )
        {
            if ( [_device supportsFamily:MTLGPUFamilyMetal3] )
            {
                heapBasedAllocation = YES;
                MTLAccelerationStructureSizes storageSizes = [self calculateSizeForPrimitiveAccelerationStructures:primitiveAccelerationDescriptors];
                MTLHeapDescriptor* heapDesc = [[MTLHeapDescriptor alloc] init];
                heapDesc.size = storageSizes.accelerationStructureSize;
                accelerationStructureHeap = [_device newHeapWithDescriptor:heapDesc];
                primitiveAccelerationStructures = [self allocateAndBuildAccelerationStructuresWithDescriptors:primitiveAccelerationDescriptors
                                                                                                         heap:accelerationStructureHeap
                                                                                         maxScratchBufferSize:storageSizes.buildScratchBufferSize
                                                                                                  signalEvent:_accelerationStructureBuildEvent];
            }
        }
    }

    // Non-Metal 3 devices, allocate each acceleration structure individually.
    if ( !heapBasedAllocation )
    {
        NSMutableArray< id<MTLAccelerationStructure> >* mutablePrimitiveAccelerationStructures = [NSMutableArray arrayWithCapacity:_meshes.count];
        id< MTLCommandBuffer > cmd = [_commandQueue commandBuffer];
        for ( MTLPrimitiveAccelerationStructureDescriptor* desc in primitiveAccelerationDescriptors )
        {
            [mutablePrimitiveAccelerationStructures addObject:[self allocateAndBuildAccelerationStructureWithDescriptor:desc commandBuffer:(id<MTLCommandBuffer>)cmd]];
        }
        [cmd encodeSignalEvent:_accelerationStructureBuildEvent value:kPrimitiveAccelerationStructureBuild];
        [cmd commit];
        primitiveAccelerationStructures = mutablePrimitiveAccelerationStructures;
    }

    MTLInstanceAccelerationStructureDescriptor* instanceAccelStructureDesc = [MTLInstanceAccelerationStructureDescriptor descriptor];
    instanceAccelStructureDesc.instancedAccelerationStructures = primitiveAccelerationStructures;

    instanceAccelStructureDesc.instanceCount = kMaxModelInstances;

    // Load instance data (two fire trucks + one sphere + floor):

    id<MTLBuffer> instanceDescriptorBuffer = [_device newBufferWithLength:sizeof(MTLAccelerationStructureInstanceDescriptor) * kMaxModelInstances options:MTLResourceStorageModeShared];
    MTLAccelerationStructureInstanceDescriptor* instanceDescriptors = (MTLAccelerationStructureInstanceDescriptor *)instanceDescriptorBuffer.contents;
    for (NSUInteger i = 0; i < kMaxModelInstances; ++i)
    {
        instanceDescriptors[i].accelerationStructureIndex = _modelInstances[i].meshIndex;
        instanceDescriptors[i].intersectionFunctionTableOffset = 0;
        instanceDescriptors[i].mask = 0xFF;
        instanceDescriptors[i].options = MTLAccelerationStructureInstanceOptionNone;

        AAPLInstanceTransform* transforms = (AAPLInstanceTransform *)(((uint8_t *)_instanceTransformBuffer.contents) + i * kAlignedInstanceTransformsStructSize);
        instanceDescriptors[i].transformationMatrix = matrix4x4_drop_last_row( transforms->modelViewMatrix );
    }
    instanceAccelStructureDesc.instanceDescriptorBuffer = instanceDescriptorBuffer;

    id< MTLCommandBuffer > cmd = [_commandQueue commandBuffer];
    [cmd encodeWaitForEvent:_accelerationStructureBuildEvent value:kPrimitiveAccelerationStructureBuild];
    _instanceAccelerationStructure = [self allocateAndBuildAccelerationStructureWithDescriptor:instanceAccelStructureDesc commandBuffer:cmd];
    [cmd encodeSignalEvent:_accelerationStructureBuildEvent value:kInstanceAccelerationStructureBuild];
    [cmd commit];

    if (heapBasedAllocation)
    {
        [_sceneHeaps addObject:accelerationStructureHeap];
    }
    else
    {
        [_sceneResources addObjectsFromArray:primitiveAccelerationStructures];
    }
}

#pragma mark - Residency

#if AAPL_SUPPORTS_RESIDENCY_SETS
- (void)buildSceneResidencySet NS_AVAILABLE(15, 18)
{
    NSError *error = nil;

    id<MTLResidencySet> sceneResidencySet = [self newResidencySetWithLabel:@"sceneResidencySet"
                                                                     error:&error];

    NSAssert(sceneResidencySet, @"The app can't create an `MTLResidencySet`! Details: %@", error ? error.localizedDescription : @"The device doesn't support `MTLResidencySet`");

    void (^addAllocationsBlock)(__unsafe_unretained id *, NSUInteger) = ^(__unsafe_unretained id *data, NSUInteger count)
    {
        [sceneResidencySet addAllocations:data
                                    count:count];
    };

    arrayToBatchMethodHelper(_sceneResources, addAllocationsBlock);
    arrayToBatchMethodHelper(_sceneHeaps, addAllocationsBlock);

    // Finalize all allocations in the residency set by calling commit.
    [sceneResidencySet commit];

    // Request residency to attempt to make the contents of the residency set resident at this point.
    [sceneResidencySet requestResidency];

    // Adding the residency set to the command queue lets Metal know that the contents of the residency set
    // have to be resident before any future command buffers submitted to the queue execute.
    [_commandQueue addResidencySet:sceneResidencySet];

    _sceneResidencySet = sceneResidencySet;
}
#endif

#pragma mark - Update State

matrix_float4x4 calculateTransform( ModelInstance instance )
{
    vector_float3 rotationAxis = {0, 1, 0};
    matrix_float4x4 rotationMatrix = matrix4x4_rotation( instance.rotation, rotationAxis );
    matrix_float4x4 translationMatrix = matrix4x4_translation( instance.position );

    return matrix_multiply(translationMatrix, rotationMatrix);
}

- (void)setStaticState
{
    for (NSUInteger i = 0; i < kMaxModelInstances; ++i)
    {
        AAPLInstanceTransform* transforms = (AAPLInstanceTransform *)(((uint8_t *)_instanceTransformBuffer.contents) + (i * kAlignedInstanceTransformsStructSize));
        transforms->modelViewMatrix = calculateTransform( _modelInstances[i] );
    }

    [self updateCameraState];

    AAPLLightData* pLightData = (AAPLLightData *)(_lightDataBuffer.contents);
    pLightData->directionalLightInvDirection = -vector_normalize((vector_float3){ 0, -6, -6 });
    pLightData->lightIntensity = 5.0f;
}

- (void)updateCameraState
{
    // Determine next safe slot:

    _cameraBufferIndex = ( _cameraBufferIndex + 1 ) % kMaxBuffersInFlight;

    // Update Projection Matrix
    AAPLCameraData* pCameraData = (AAPLCameraData *)_cameraDataBuffers[_cameraBufferIndex].contents;
    pCameraData->projectionMatrix = _projectionMatrix;

    // Update Camera Position (and View Matrix):

    vector_float3 camPos = (vector_float3){ cosf( _cameraAngle ) * 10.0f, 5, sinf(_cameraAngle) * 22.5f };
    _cameraAngle += (0.02 * _cameraPanSpeedFactor);
    if ( _cameraAngle >= 2 * M_PI )
    {
        _cameraAngle -= (2 * M_PI);
    }

    pCameraData->viewMatrix = matrix4x4_translation( -camPos );
    pCameraData->cameraPosition = camPos;
    pCameraData->metallicBias = _metallicBias;
    pCameraData->roughnessBias = _roughnessBias;
}

#pragma mark - Rendering

- (void)encodeSceneRendering:(id<MTLRenderCommandEncoder >)renderEncoder
{
#if AAPL_SUPPORTS_RESIDENCY_SETS
    if (!_useResidencySet)
#endif
    {
        // Flag residency for indirectly referenced heaps to make the driver put them into GPU memory.
        arrayToBatchMethodHelper(_sceneHeaps, ^(__unsafe_unretained id *data, NSUInteger count)
        {
            [renderEncoder useHeaps:data
                              count:count
                             stages:MTLRenderStageFragment];
        });

        // Flag residency for indirectly referenced resources to make the driver put them into GPU memory.
        arrayToBatchMethodHelper(_sceneResources, ^(__unsafe_unretained id *data, NSUInteger count)
        {
            [renderEncoder useResources:data
                                  count:count
                                  usage:MTLResourceUsageRead
                                 stages:MTLRenderStageFragment];
        });
    }

    for ( NSUInteger i = 0; i < kMaxModelInstances; ++i )
    {
        AAPLMesh* mesh = _meshes[ _modelInstances[ i ].meshIndex ];
        MTKMesh *metalKitMesh = mesh.metalKitMesh;

        // Set the mesh's vertex buffers.
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if ((NSNull *)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        // Draw each submesh of the mesh.
        for ( NSUInteger submeshIndex = 0; submeshIndex < mesh.submeshes.count; ++submeshIndex )
        {
            AAPLSubmesh* submesh = mesh.submeshes[ submeshIndex ];

            // Access textures directly from the argument buffer and avoid rebinding them individually.
            // `SubmeshKeypath` provides the path to the argument buffer containing the texture data
            // for this submesh. The shader navigates the scene argument buffer using this key
            // to find the textures.
            AAPLSubmeshKeypath submeshKeypath = {
                .instanceID = (uint32_t)i,
                .submeshID = (uint32_t)submeshIndex
            };

            MTKSubmesh *metalKitSubmesh = submesh.metalKitSubmesh;

            [renderEncoder setVertexBuffer:_instanceTransformBuffer
                                    offset:kAlignedInstanceTransformsStructSize * i
                                   atIndex:BufferIndexInstanceTransforms];

            [renderEncoder setVertexBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
            [renderEncoder setFragmentBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
            [renderEncoder setFragmentBuffer:_lightDataBuffer offset:0 atIndex:BufferIndexLightData];

            // Bind the scene and provide the keypath to retrieve this submesh's data.
            [renderEncoder setFragmentBuffer:_sceneArgumentBuffer offset:0 atIndex:SceneIndex];
            [renderEncoder setFragmentBytes:&submeshKeypath length:sizeof(AAPLSubmeshKeypath) atIndex:BufferIndexSubmeshKeypath];

            [renderEncoder drawIndexedPrimitives:metalKitSubmesh.primitiveType
                                      indexCount:metalKitSubmesh.indexCount
                                       indexType:metalKitSubmesh.indexType
                                     indexBuffer:metalKitSubmesh.indexBuffer.buffer
                               indexBufferOffset:metalKitSubmesh.indexBuffer.offset];
        }

    }

}

- (void)copyDepthStencilConfigurationFrom:(MTLRenderPassDescriptor *)src to:(MTLRenderPassDescriptor *)dest
{
    dest.depthAttachment.loadAction     = src.depthAttachment.loadAction;
    dest.depthAttachment.clearDepth     = src.depthAttachment.clearDepth;
    dest.depthAttachment.texture        = src.depthAttachment.texture;
    dest.stencilAttachment.loadAction   = src.stencilAttachment.loadAction;
    dest.stencilAttachment.clearStencil = src.stencilAttachment.clearStencil;
    dest.stencilAttachment.texture      = src.stencilAttachment.texture;
}

- (void)generateGaussMipmapsForTexture:(id<MTLTexture>)texture commandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MPSImageGaussianBlur* gauss = [[MPSImageGaussianBlur alloc] initWithDevice:_device
                                                                         sigma:5.0f];
    MTLTextureDescriptor* tmpDesc = [[MTLTextureDescriptor alloc] init];
    tmpDesc.textureType = MTLTextureType2D;
    tmpDesc.pixelFormat = MTLPixelFormatRG11B10Float;
    tmpDesc.mipmapLevelCount = 1;
    tmpDesc.usage = MTLResourceUsageRead | MTLResourceUsageWrite;
    tmpDesc.resourceOptions = MTLResourceStorageModePrivate;

    id< MTLTexture > src = _rtReflectionMap;

    uint32_t newW = (uint32_t)_rtReflectionMap.width;
    uint32_t newH = (uint32_t)_rtReflectionMap.height;

    id< MTLEvent > event = [_device newEvent];
    uint64_t count = 0u;
    [commandBuffer encodeSignalEvent:event value:count];

    while ( count+1 < _rtReflectionMap.mipmapLevelCount )
    {
        [commandBuffer pushDebugGroup:[NSString stringWithFormat:@"Mip level: %llu", count]];

        tmpDesc.width = newW;
        tmpDesc.height = newH;

        id< MTLTexture > dst = [_rtMipmappingHeap newTextureWithDescriptor:tmpDesc];

        [gauss encodeToCommandBuffer:commandBuffer
                       sourceTexture:src
                  destinationTexture:dst];

        ++count;
        [commandBuffer encodeSignalEvent:event value:count];

        [commandBuffer encodeWaitForEvent:event value:count];
        id<MTLTexture> targetMip = [_rtReflectionMap newTextureViewWithPixelFormat:MTLPixelFormatRG11B10Float
                                                                       textureType:MTLTextureType2D
                                                                            levels:NSMakeRange(count, 1)
                                                                            slices:NSMakeRange(0, 1)];

        MTLRenderPassDescriptor* rpd = [[MTLRenderPassDescriptor alloc] init];
        rpd.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
        rpd.colorAttachments[0].texture = targetMip;

        id< MTLRenderCommandEncoder > blit = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
        [blit setCullMode:MTLCullModeNone];
        [blit setRenderPipelineState:_rtMipmapPipeline];
        [blit setFragmentTexture:dst atIndex:0];
        [blit drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [blit endEncoding];

        src = targetMip;

        newW = newW / 2;
        newH = newH / 2;

        [commandBuffer popDebugGroup];
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Per-frame updates here.

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Render Commands";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];

    [self updateCameraState];

    // Delay getting the currentRenderPassDescriptor until the renderer absolutely needs it to avoid
    // holding onto the drawable and blocking the display pipeline any longer than necessary.
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if (renderPassDescriptor != nil)
    {

        // When ray tracing is in an enabled state, first render a thin G-Buffer
        // that contains position and reflection direction data. Then, dispatch a
        // compute kernel that ray traces mirror-like reflections from this data.

        if ( _renderMode == RMMetalRaytracing || _renderMode == RMReflectionsOnly )
        {
            MTLRenderPassDescriptor* gbufferPass = [MTLRenderPassDescriptor new];
            gbufferPass.colorAttachments[0].loadAction = MTLLoadActionClear;
            gbufferPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
            gbufferPass.colorAttachments[0].storeAction = MTLStoreActionStore;
            gbufferPass.colorAttachments[0].texture = _thinGBuffer.positionTexture;

            gbufferPass.colorAttachments[1].loadAction = MTLLoadActionClear;
            gbufferPass.colorAttachments[1].clearColor = MTLClearColorMake(0, 0, 0, 1);
            gbufferPass.colorAttachments[1].storeAction = MTLStoreActionStore;
            gbufferPass.colorAttachments[1].texture = _thinGBuffer.directionTexture;

            [self copyDepthStencilConfigurationFrom:renderPassDescriptor to:gbufferPass];
            gbufferPass.depthAttachment.storeAction = MTLStoreActionStore;

            // Create a render command encoder.
            [commandBuffer pushDebugGroup:@"Render Thin G-Buffer"];
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:gbufferPass];

            renderEncoder.label = @"ThinGBufferRenderEncoder";

            // Set the render command encoder state.
            [renderEncoder setCullMode:MTLCullModeFront];
            [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
            [renderEncoder setRenderPipelineState:_gbufferPipelineState];
            [renderEncoder setDepthStencilState:_depthState];

            // Encode all draw calls for the scene.
            [self encodeSceneRendering:renderEncoder];

            // Finish encoding commands.
            [renderEncoder endEncoding];
            [commandBuffer popDebugGroup];

            // The ray-traced reflections.
            [commandBuffer pushDebugGroup:@"Raytrace Compute"];
            [commandBuffer encodeWaitForEvent:_accelerationStructureBuildEvent value:kInstanceAccelerationStructureBuild];
            id<MTLComputeCommandEncoder> compEnc = [commandBuffer computeCommandEncoder];
            compEnc.label = @"RaytracedReflectionsComputeEncoder";
            [compEnc setTexture:_rtReflectionMap atIndex:OutImageIndex];
            [compEnc setTexture:_thinGBuffer.positionTexture atIndex:ThinGBufferPositionIndex];
            [compEnc setTexture:_thinGBuffer.directionTexture atIndex:ThinGBufferDirectionIndex];
            [compEnc setTexture:_skyMap atIndex:AAPLSkyDomeTexture];

            // Bind the root of the argument buffer for the scene.
            [compEnc setBuffer:_sceneArgumentBuffer offset:0 atIndex:SceneIndex];

            // Bind the prebuilt acceleration structure.
            [compEnc setAccelerationStructure:_instanceAccelerationStructure atBufferIndex:AccelerationStructureIndex];

            [compEnc setBuffer:_instanceTransformBuffer offset:0 atIndex:BufferIndexInstanceTransforms];
            [compEnc setBuffer:_cameraDataBuffers[_cameraBufferIndex] offset:0 atIndex:BufferIndexCameraData];
            [compEnc setBuffer:_lightDataBuffer offset:0 atIndex:BufferIndexLightData];

            // Set the ray tracing reflection kernel.
            [compEnc setComputePipelineState:_rtReflectionPipeline];

#if AAPL_SUPPORTS_RESIDENCY_SETS
            if (!_useResidencySet)
#endif
            {
                // Flag residency for indirectly referenced heaps to make the driver put them into GPU memory.
                arrayToBatchMethodHelper(_sceneHeaps, ^(__unsafe_unretained id *data, NSUInteger count)
                {
                    [compEnc useHeaps:data
                                count:count];
                });

                // Flag residency for indirectly referenced resources to make the driver put them into GPU memory.
                arrayToBatchMethodHelper(_sceneResources, ^(__unsafe_unretained id *data, NSUInteger count)
                {
                    [compEnc useResources:data
                                    count:count
                                    usage:MTLResourceUsageRead];
                });
            }

            // Determine the dispatch grid size and dispatch compute.

            NSUInteger w = _rtReflectionPipeline.threadExecutionWidth;
            NSUInteger h = _rtReflectionPipeline.maxTotalThreadsPerThreadgroup / w;
            MTLSize threadsPerThreadgroup = MTLSizeMake( w, h, 1 );
            MTLSize threadsPerGrid = MTLSizeMake(_rtReflectionMap.width, _rtReflectionMap.height, 1);

            [compEnc dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];

            [compEnc endEncoding];
            [commandBuffer popDebugGroup];

            // Generally, for accurate rough reflections, a renderer performs cone ray tracing in
            // the ray tracing kernel.  In this case, the renderer simplifies this by blurring the
            // mirror-like reflections along the mipchain.  The renderer later biases the miplevel
            // that the GPU samples when reading the reflection in the accumulation pass.

            [commandBuffer pushDebugGroup:@"Generate Reflection Mipmaps"];
            const BOOL gaussianBlur = YES;
            if ( gaussianBlur )
            {
                [self generateGaussMipmapsForTexture:_rtReflectionMap commandBuffer:commandBuffer];
            }
            else
            {
                id<MTLBlitCommandEncoder> genMips = [commandBuffer blitCommandEncoder];
                [genMips generateMipmapsForTexture:_rtReflectionMap];
                [genMips endEncoding];
            }
            [commandBuffer popDebugGroup];
        }

        // Encode the forward pass.

        MTLRenderPassDescriptor* rpd = view.currentRenderPassDescriptor;
        id<MTLTexture> drawableTexture = rpd.colorAttachments[0].texture;
        rpd.colorAttachments[0].texture = _rawColorMap;

        [commandBuffer pushDebugGroup:@"Forward Scene Render"];
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
        renderEncoder.label = @"ForwardPassRenderEncoder";

        if ( _renderMode == RMMetalRaytracing )
        {
            [renderEncoder setRenderPipelineState:_pipelineState];
        }
        else if ( _renderMode == RMNoRaytracing )
        {
            [renderEncoder setRenderPipelineState:_pipelineStateNoRT];
        }
        else if ( _renderMode == RMReflectionsOnly )
        {
            [renderEncoder setRenderPipelineState:_pipelineStateReflOnly];
        }

        [renderEncoder setCullMode:MTLCullModeFront];
        [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setFragmentTexture:_rtReflectionMap atIndex:AAPLTextureIndexReflections];
        [renderEncoder setFragmentTexture:_skyMap atIndex:AAPLSkyDomeTexture];

        [self encodeSceneRendering:renderEncoder];

        // Encode the skybox rendering.

        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_skyboxPipelineState];

        [renderEncoder setVertexBuffer:_cameraDataBuffers[_cameraBufferIndex]
                                offset:0
                               atIndex:BufferIndexCameraData];

        [renderEncoder setFragmentTexture:_skyMap atIndex:0];

        MTKMesh* metalKitMesh = _skybox.metalKitMesh;
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if ((NSNull *)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        for (MTKSubmesh *submesh in metalKitMesh.submeshes)
        {
            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                      indexCount:submesh.indexCount
                                       indexType:submesh.indexType
                                     indexBuffer:submesh.indexBuffer.buffer
                               indexBufferOffset:submesh.indexBuffer.offset];
        }

        [renderEncoder endEncoding];
        [commandBuffer popDebugGroup];

        // Clamp values to the bloom threshold.
        {
            [commandBuffer pushDebugGroup:@"Bloom Threshold"];
            MTLRenderPassDescriptor* rpd = [[MTLRenderPassDescriptor alloc] init];
            rpd.colorAttachments[0].loadAction = MTLLoadActionDontCare;
            rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
            rpd.colorAttachments[0].texture = _bloomThresholdMap;

            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
            [renderEncoder pushDebugGroup:@"Postprocessing"];
            [renderEncoder setRenderPipelineState:_bloomThresholdPipeline];
            [renderEncoder setFragmentTexture:_rawColorMap atIndex:0];

            float threshold = 2.0f;
            [renderEncoder setFragmentBytes:&threshold length:sizeof(float) atIndex:0];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];
            [commandBuffer popDebugGroup];
        }

        // Blur the bloom.
        {
            [commandBuffer pushDebugGroup:@"Bloom Blur"];
            MPSImageGaussianBlur* blur = [[MPSImageGaussianBlur alloc] initWithDevice:_device sigma:5.0f];
            [blur encodeToCommandBuffer:commandBuffer
                          sourceTexture:_bloomThresholdMap
                     destinationTexture:_bloomBlurMap];
            [commandBuffer popDebugGroup];
        }

        // Merge the postprocessing results with the scene rendering.
        {
            [commandBuffer pushDebugGroup:@"Final Merge"];
            MTLRenderPassDescriptor* rpd = [[MTLRenderPassDescriptor alloc] init];
            rpd.colorAttachments[0].loadAction = MTLLoadActionDontCare;
            rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
            rpd.colorAttachments[0].texture = drawableTexture;

            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
            [renderEncoder pushDebugGroup:@"Postprocessing Merge"];
            [renderEncoder setRenderPipelineState:_postMergePipeline];
            [renderEncoder setFragmentBytes:&_exposure length:sizeof(float) atIndex:0];
            [renderEncoder setFragmentTexture:_rawColorMap atIndex:0];
            [renderEncoder setFragmentTexture:_bloomBlurMap atIndex:1];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:6];

            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];
            [commandBuffer popDebugGroup];
        }

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (matrix_float4x4)projectionMatrixWithAspect:(float)aspect
{
    return matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 250.0f);
}

#pragma mark - Event Handling

/// Respond to drawable size or orientation changes.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    float aspect = size.width / (float)size.height;
    _projectionMatrix = [self projectionMatrixWithAspect:aspect];

    // The passed-in size is already in backing coordinates.
    [self resizeRTReflectionMapTo:size];
}

- (void)setRenderMode:(RenderMode)renderMode
{
    _renderMode = renderMode;
}

- (void)setCameraPanSpeedFactor:(float)speedFactor
{
    _cameraPanSpeedFactor = speedFactor;
}

- (void)setMetallicBias:(float)metallicBias
{
    _metallicBias = metallicBias;
}

- (void)setRoughnessBias:(float)roughnessBias
{
    _roughnessBias = roughnessBias;
}

- (void)setExposure:(float)exposure
{
    _exposure = exposure;
}

@end
