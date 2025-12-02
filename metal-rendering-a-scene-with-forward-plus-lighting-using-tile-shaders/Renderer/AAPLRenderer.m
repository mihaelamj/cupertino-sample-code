/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of renderer class that perfoms Metal setup and per-frame rendering.
*/
@import ModelIO;
@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLMesh.h"
#import "AAPLMathUtilities.h"

// Include header shared between C code and .metal files.
#import "AAPLShaderTypes.h"

#import <simd/simd.h>

// The maximum number of command buffers in flight.
static const NSUInteger AAPLMaxBuffersInFlight = 3;

// The number of vertices in the fairy model.
static const NSUInteger AAPLNumFairyVertices = 7;

static const MTLPixelFormat AAPLDepthDataPixelFormat = MTLPixelFormatR32Float;

static const MTLPixelFormat AAPLDepthBufferPixelFormat = MTLPixelFormatDepth32Float;

/// The main class that performs the rendering.
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    // Vertex descriptor for models loaded with MetalKit and used for render pipelines.
    MTLVertexDescriptor *_defaultVertexDescriptor;

    // Pipeline state objects.
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLRenderPipelineState> _depthPrePassPipelineState;
    id <MTLRenderPipelineState> _lightBinCreationPipelineState;
    id <MTLRenderPipelineState> _lightCullingPipelineState;
    id <MTLRenderPipelineState> _lightResolvePipelineState;
    id <MTLRenderPipelineState> _forwardLightingPipelineState;
    id <MTLRenderPipelineState> _fairyPipelineState;

    // Depth state objects.
    id <MTLDepthStencilState> _defaultDepthState;
    id <MTLDepthStencilState> _relaxedDepthState;
    id <MTLDepthStencilState> _dontWriteDepthState;

    // Buffers used to store dynamically-changing per-frame data.
    id <MTLBuffer> _frameDataBuffers[AAPLMaxBuffersInFlight];

    // Buffers used to story dynamically-changing light positions.
    id <MTLBuffer> _lightWorldPositions[AAPLMaxBuffersInFlight];
    id <MTLBuffer> _lightEyePositions[AAPLMaxBuffersInFlight];

    CGSize _drawableSize;

    // Current buffer to fill with per frame data and set for the current frame.
    uint8_t _currentBufferIndex;

    // Buffer for constant light data.
    id <MTLBuffer> _lightsData;

    // Field of view used to create perspective projection (in radians).
    float _fov;

    // Near-depth plane for the projection matrix.
    float _nearPlane;

    // Far-depth plane for the projection matrix.
    float _farPlane;

    // Projection matrix calculated as a function of the view size.
    matrix_float4x4 _projectionMatrix;
    
    // Current rotation of the object (in radians).
    float _rotation;

	// Array of app-specific mesh objects in the scene.
    NSArray<AAPLMesh *> *_meshes;

    // Custom render pass descriptor used to render to the view's drawable
    MTLRenderPassDescriptor *_viewRenderPassDescriptor;

    // Mesh buffer for fairies.
    id<MTLBuffer> _fairy;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if(self)
    {
        _device = view.device;

        // This sample requires APIs avaliable with the MTLGPUFamilyApple4 feature set
        //   (which is avaliable on iOS devices with A11 GPUs or later or Macs with Apple Silicon).
        //   If the MTLGPUFamilyApple4 feature set is unavaliable, you would need to implement a
        //   backup path that does not use many of the APIs demonstrated in this sample.
        NSAssert([_device supportsFamily:MTLGPUFamilyApple4],
                 @"Sample requires MTLGPUFamilyApple4 (on available on Macs \
                 with Apple Silicon or iOS devices with an A11 or later)");

        _inFlightSemaphore = dispatch_semaphore_create(AAPLMaxBuffersInFlight);
        [self loadMetalWithMetalKitView:view];
        [self loadAssets];
        [self populateLights];
    }

    return self;
}

/// Create Metal render state objects.
- (void)loadMetalWithMetalKitView:(nonnull MTKView *)view
{
    NSError *error;

    // Create and load the basic Metal state objects.

    // Load all the shader files with a .metal file extension in the project.
    id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    // Create and allocate frame data buffer objects.
    for(NSUInteger i = 0; i < AAPLMaxBuffersInFlight; i++)
    {
        // Indicate shared storage so that both the CPU and the GPU can access the buffers.
        const MTLResourceOptions storageMode = MTLResourceStorageModeShared;

        _frameDataBuffers[i] = [_device newBufferWithLength:sizeof(AAPLFrameData)
                                                  options:storageMode];

        _frameDataBuffers[i].label = [NSString stringWithFormat:@"FrameDataBuffer%lu", i];

        _lightWorldPositions[i] = [_device newBufferWithLength:sizeof(vector_float4)*AAPLNumLights
                                                  options:storageMode];

        _lightWorldPositions[i].label = [NSString stringWithFormat:@"LightPositions%lu", i];

        _lightEyePositions[i] = [_device newBufferWithLength:sizeof(vector_float4)*AAPLNumLights
                                                          options:storageMode];

        _lightEyePositions[i].label = [NSString stringWithFormat:@"LightPositionsEyeSpace%lu", i];
    }

    // Create a vertex descriptor for the Metal pipeline. Specify the layout of vertices the
    //   pipeline should expect. The layout below keeps attributes used to calculate vertex shader
    //   output position (world position, skinning, tweening weights) separate from other
    //   attributes (texture coordinates, normals). This generally maximizes pipeline efficiency.

    _defaultVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    // Positions.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

    // Texture coordinates.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 0;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Normals.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 8;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Tangents.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].offset = 16;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Bitangents.
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].offset = 24;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Position buffer layout.
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Generic attribute buffer layout.
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 32;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    // Set view's depth stencil pixel format to Invalid.  This app will manually manage it's own
    // depth buffer, not depend on the depth buffer managed by MTKView
    view.depthStencilPixelFormat = MTLPixelFormatInvalid;

    // Create a render pipeline state descriptor.
    MTLRenderPipelineDescriptor * renderPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];

    renderPipelineStateDescriptor.sampleCount = AAPLNumSamples;
    renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;

    renderPipelineStateDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = view.colorPixelFormat;
    renderPipelineStateDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = AAPLDepthDataPixelFormat;

    renderPipelineStateDescriptor.depthAttachmentPixelFormat = AAPLDepthBufferPixelFormat;

    // Set unique descriptor values for the depth pre-pass pipeline state.
    {
        id <MTLFunction> depthPrePassVertexFunction = [defaultLibrary newFunctionWithName:@"depth_pre_pass_vertex"];
        id <MTLFunction> depthPrePassFragmentFunction = [defaultLibrary newFunctionWithName:@"depth_pre_pass_fragment"];
        renderPipelineStateDescriptor.label = @"Depth Pre-Pass";
        renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;
        renderPipelineStateDescriptor.vertexFunction = depthPrePassVertexFunction;
        renderPipelineStateDescriptor.fragmentFunction = depthPrePassFragmentFunction;

        _depthPrePassPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                             error:&error];

        NSAssert(_depthPrePassPipelineState, @"Failed to create pipeline state: %@", error);
    }

    // Set unique descriptor values for the standard material pipeline state.
    {
        id <MTLFunction> vertexStandardMaterial = [defaultLibrary newFunctionWithName:@"forward_lighting_vertex"];
        id <MTLFunction> fragmentStandardMaterial = [defaultLibrary newFunctionWithName:@"forward_lighting_fragment"];

        renderPipelineStateDescriptor.label = @"Forward Lighting";
        renderPipelineStateDescriptor.vertexDescriptor = _defaultVertexDescriptor;
        renderPipelineStateDescriptor.vertexFunction = vertexStandardMaterial;
        renderPipelineStateDescriptor.fragmentFunction = fragmentStandardMaterial;
        _forwardLightingPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                                error:&error];

        NSAssert(_forwardLightingPipelineState, @"Failed to create pipeline state: %@", error);
    }

    // Set unique descriptor values for the fairy pipeline state.
    {
        id <MTLFunction> fairyVertexFunction = [defaultLibrary newFunctionWithName:@"fairy_vertex"];
        id <MTLFunction> fairyFragmentFunction = [defaultLibrary newFunctionWithName:@"fairy_fragment"];

        renderPipelineStateDescriptor.label = @"Fairy";
        renderPipelineStateDescriptor.vertexDescriptor = nil;
        renderPipelineStateDescriptor.vertexFunction = fairyVertexFunction;
        renderPipelineStateDescriptor.fragmentFunction = fairyFragmentFunction;
        _fairyPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineStateDescriptor
                                                                      error:&error];

        NSAssert(_fairyPipelineState, @"Failed to create pipeline state: %@", error);
    }

    {
        id <MTLFunction> binCreationKernel = [defaultLibrary newFunctionWithName:@"create_bins"];

        MTLTileRenderPipelineDescriptor *binCreationPipelineDescriptor = [MTLTileRenderPipelineDescriptor new];
        binCreationPipelineDescriptor.label = @"Light Bin Creation";
        binCreationPipelineDescriptor.rasterSampleCount = AAPLNumSamples;
        binCreationPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = view.colorPixelFormat;
        binCreationPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = AAPLDepthDataPixelFormat;
        binCreationPipelineDescriptor.threadgroupSizeMatchesTileSize = YES;
        binCreationPipelineDescriptor.tileFunction = binCreationKernel;
        _lightBinCreationPipelineState = [_device newRenderPipelineStateWithTileDescriptor:binCreationPipelineDescriptor
                                                                                   options:0 reflection:nil error:&error];

        NSAssert(_lightBinCreationPipelineState, @"Failed to create pipeline state: %@", error);
    }

    // Create a tile render pipeline state descriptor for the culling pipeline state.
    {
        MTLTileRenderPipelineDescriptor *tileRenderPipelineDescriptor = [MTLTileRenderPipelineDescriptor new];
        id <MTLFunction> lightCullingKernel = [defaultLibrary newFunctionWithName:@"cull_lights"];
        tileRenderPipelineDescriptor.tileFunction = lightCullingKernel;
        tileRenderPipelineDescriptor.label = @"Light Culling";
        tileRenderPipelineDescriptor.rasterSampleCount = AAPLNumSamples;

        tileRenderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = view.colorPixelFormat;
        tileRenderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = AAPLDepthDataPixelFormat;

        tileRenderPipelineDescriptor.threadgroupSizeMatchesTileSize = YES;
        _lightCullingPipelineState = [_device newRenderPipelineStateWithTileDescriptor:tileRenderPipelineDescriptor
                                                                               options:0 reflection:nil error:&error];

        NSAssert(_lightCullingPipelineState, @"Failed to create pipeline state: %@", error);
    }

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];

    // Create a depth state with depth buffer write enabled.
    {
        // Use `MTLCompareFunctionLess` because you render on a clean depth buffer.
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = YES;
        _defaultDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Create a depth state with depth buffer write disabled and set the comparison function to
    //   `MTLCompareFunctionLessEqual`.
    {
        // The comparison function is `MTLCompareFunctionLessEqual` instead of `MTLCompareFunctionLess`.
        //   The geometry pass renders to a pre-populated depth buffer (depth pre-pass) so each
        //   fragment needs to pass if its z-value is equal to the existing value already in the
        //   depth buffer.
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStateDesc.depthWriteEnabled = NO;
        _relaxedDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Create a depth state with depth buffer write disabled.
    {
        depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStateDesc.depthWriteEnabled = NO;
        _dontWriteDepthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    }

    // Create a render pass descriptor to render to the drawable
    {
        _viewRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
        _viewRenderPassDescriptor.stencilAttachment.clearStencil = 0;

        _viewRenderPassDescriptor.tileWidth = AAPLTileWidth;
        _viewRenderPassDescriptor.tileHeight = AAPLTileHeight;
        _viewRenderPassDescriptor.threadgroupMemoryLength = AAPLThreadgroupBufferSize + AAPLTileDataSize;

        if(AAPLNumSamples > 1)
        {
            _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].storeAction = MTLStoreActionMultisampleResolve;
        }
        else
        {
            _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].storeAction = MTLStoreActionStore;
        }
    }

    // Create the command queue.
    _commandQueue = [_device newCommandQueue];
}

/// Load models, textures, and other assets.
- (void)loadAssets
{
    // Create and load assets into Metal objects.
    NSError *error;

    // Creata a Model I/O vertex descriptor so that the format and layout of Model I/O mesh vertices
    //   fits the Metal render pipeline's vertex descriptor layout.
    MDLVertexDescriptor *modelIOVertexDescriptor =
        MTKModelIOVertexDescriptorFromMetal(_defaultVertexDescriptor);

    // Indicate how each Metal vertex descriptor attribute maps to each Model I/O attribute.
    modelIOVertexDescriptor.attributes[AAPLVertexAttributePosition].name  = MDLVertexAttributePosition;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeNormal].name    = MDLVertexAttributeNormal;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeTangent].name   = MDLVertexAttributeTangent;
    modelIOVertexDescriptor.attributes[AAPLVertexAttributeBitangent].name = MDLVertexAttributeBitangent;

    NSURL *modelFileURL = [[NSBundle mainBundle] URLForResource:@"Meshes/Temple.obj" withExtension:nil];

    NSAssert(modelFileURL, @"Could not find model (%@) file in bundle", modelFileURL.absoluteString);

    _meshes = [AAPLMesh newMeshesFromURL:modelFileURL
                 modelIOVertexDescriptor:modelIOVertexDescriptor
                             metalDevice:_device
                                   error:&error];

    NSAssert(_meshes, @"Could not find model (%@) file in bundle", error);
    
    _lightsData = [_device newBufferWithLength:sizeof(AAPLPointLight)*AAPLNumLights options:0];
    _lightsData.label = @"LightData";

    NSAssert(_lightsData, @"Could not create lights data buffer");

    // Create a simple 2D triangle strip circle mesh for the fairies.
    {
        static const float FairySize = 2.5;
        AAPLSimpleVertex fairyVertices[AAPLNumFairyVertices];
        const float angle = 2*M_PI/(float)AAPLNumFairyVertices;
        for(int vtx = 0; vtx < AAPLNumFairyVertices; vtx++)
        {
            int point = (vtx%2) ? (vtx+1)/2 : -vtx/2;
            fairyVertices[vtx].position =  (vector_float2){sin(point*angle), cos(point*angle)};
            fairyVertices[vtx].position *= FairySize;
        }

        _fairy = [_device newBufferWithBytes:fairyVertices length:sizeof(fairyVertices) options:0];
    }
}

/// Initialize light positions and colors.
- (void)populateLights
{
    AAPLPointLight *light_data = (AAPLPointLight*)_lightsData.contents;
    vector_float4 *light_position = (vector_float4*)_lightWorldPositions[0].contents;

    srandom(0x134e5348);

    for(NSUInteger lightId = 0; lightId < AAPLNumLights; lightId++)
    {
        float distance = 0;
        float height = 0;
        float angle = 0;
        if(lightId < AAPLNumLights/4) {
            distance = random_float(140,260);
            height = random_float(140,150);
            angle = random_float(0, M_PI*2);
        } else if(lightId < (AAPLNumLights*3)/4) {
            distance = random_float(350,362);
            height = random_float(140,400);
            angle = random_float(0, M_PI*2);
        } else if(lightId < (AAPLNumLights*15)/16) {
            distance = random_float(400,480);
            height = random_float(68,80);
            angle = random_float(0, M_PI*2);
        } else {
            distance = random_float(40,40);
            height = random_float(220,350);
            angle = random_float(0, M_PI*2);
        }

        light_data->lightRadius = random_float(25,35);
        *light_position = (vector_float4){ distance*sinf(angle),height,distance*cosf(angle),light_data->lightRadius};
        light_data->lightSpeed = random_float(0.003,0.015);
        int colorId = random()%3;
        if(colorId == 0) {
            light_data->lightColor = (vector_float3){random_float(2,3),random_float(0,2),random_float(0,2)};
        } else if ( colorId == 1) {
            light_data->lightColor = (vector_float3){random_float(0,2),random_float(2,3),random_float(0,2)};
        } else {
            light_data->lightColor = (vector_float3){random_float(0,2),random_float(0,2),random_float(2,3)};
        }

        light_data++;
        light_position++;
    }

    memcpy(_lightWorldPositions[1].contents, _lightWorldPositions[0].contents, AAPLNumLights * sizeof(vector_float3));
    memcpy(_lightWorldPositions[2].contents, _lightWorldPositions[0].contents, AAPLNumLights * sizeof(vector_float3));
}

/// Update light positions.
- (void)updateLights
{
    int previousFramesBufferIndex = (_currentBufferIndex+AAPLMaxBuffersInFlight-1)%AAPLMaxBuffersInFlight;

    AAPLPointLight *lightData = (AAPLPointLight*)((char*)_lightsData.contents);

    const AAPLFrameData * frameData = (AAPLFrameData*)_frameDataBuffers[_currentBufferIndex].contents;
    const matrix_float4x4 viewMatrix = frameData->viewMatrix;

    vector_float4 *previousWorldSpacePositions =
        (vector_float4*) _lightWorldPositions[previousFramesBufferIndex].contents;

    vector_float4 *currentWorldSpaceLightPositions =
        (vector_float4*) _lightWorldPositions[_currentBufferIndex].contents;

    vector_float4 *currentEyeSpaceLightPositions =
        (vector_float4*) _lightEyePositions[_currentBufferIndex].contents;

    for(int i = 0; i < AAPLNumLights; i++)
    {
        matrix_float4x4 rotation = matrix4x4_rotation(lightData[i].lightSpeed, 0, 1, 0);

        vector_float4 previousWorldSpacePosition = {
            previousWorldSpacePositions[i].x,
            previousWorldSpacePositions[i].y,
            previousWorldSpacePositions[i].z,
            1
        };

        vector_float4 currentWorldSpacePosition = matrix_multiply(rotation, previousWorldSpacePosition);

        vector_float4 currentEyeSpacePosition = matrix_multiply(viewMatrix, currentWorldSpacePosition);

        currentWorldSpacePosition.w = lightData[i].lightRadius;
        currentEyeSpacePosition.w = lightData[i].lightRadius;

        currentWorldSpaceLightPositions[i] = currentWorldSpacePosition;
        currentEyeSpaceLightPositions[i] = currentEyeSpacePosition;
    }
}

/// Update app state for the current frame.
- (void)updateFrameState
{
    _currentBufferIndex = (_currentBufferIndex + 1) % AAPLMaxBuffersInFlight;

    AAPLFrameData * frameData = (AAPLFrameData*)_frameDataBuffers[_currentBufferIndex].contents;

    // Update ambient light color.
	vector_float3 ambientLightColor = {0.05, 0.05, 0.05};
    frameData->ambientLightColor = ambientLightColor;

    // Update directional light direction in world space.
	vector_float3 directionalLightDirection = {1.0, -1.0, 1.0};
    frameData->directionalLightDirection = directionalLightDirection;

    // Update directional light color.
    vector_float3 directionalLightColor = {.4, .4, .4};
    frameData->directionalLightColor = directionalLightColor;;

    // Set projection matrix and calculate inverted projection matrix.
    frameData->projectionMatrix = _projectionMatrix;
    frameData->projectionMatrixInv = matrix_invert(_projectionMatrix);
    frameData->depthUnproject = vector2(_farPlane / (_farPlane - _nearPlane), (-_farPlane * _nearPlane) / (_farPlane - _nearPlane));

    // Set screen dimensions.
    frameData->framebufferWidth = (uint)_drawableSize.width;
    frameData->framebufferHeight = (uint)_drawableSize.height;

    float fovScale = tanf(0.5 * _fov) * 2.0;
    float aspectRatio = (float)frameData->framebufferWidth / frameData->framebufferHeight;
    frameData->screenToViewSpace = vector3(fovScale / frameData->framebufferHeight, -fovScale * 0.5f * aspectRatio, -fovScale * 0.5f);

    // Calculate new view matrix and inverted view matrix.
    frameData->viewMatrix = matrix_multiply(matrix4x4_translation(0.0, -75, 1000.5),
                                           matrix_multiply(matrix4x4_rotation(-0.5, (vector_float3){1,0,0}),
                                                           matrix4x4_rotation(_rotation, (vector_float3){0,1,0} )));
    frameData->viewMatrixInv = matrix_invert(frameData->viewMatrix);

    vector_float3 rotationAxis = {0, 1, 0};
    matrix_float4x4 modelMatrix = matrix4x4_rotation(0, rotationAxis);
    matrix_float4x4 translation = matrix4x4_translation(0.0, 0, 0);
    modelMatrix = matrix_multiply(modelMatrix, translation);

    frameData->modelViewMatrix = matrix_multiply(frameData->viewMatrix, modelMatrix);
    frameData->modelMatrix = modelMatrix;

    frameData->normalMatrix = matrix3x3_upper_left(frameData->modelViewMatrix);
    frameData->normalMatrix = matrix_invert(matrix_transpose(frameData->normalMatrix));

    _rotation += 0.002f;

    [self updateLights];
}

/// Called whenever the view changes orientation or size.
- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	_drawableSize = size;

    // Update the aspect ratio and projection matrix because the view orientation
    //   or size has changed.
	float aspect = size.width / (float)size.height;
    _fov = 65.0f * (M_PI / 180.0f);
    _nearPlane = 1.0f;
    _farPlane = 1500.0f;
    _projectionMatrix = matrix_perspective_left_hand(_fov, aspect, _nearPlane, _farPlane);

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
    textureDescriptor.width        = size.width;
    textureDescriptor.height      = size.height;
    textureDescriptor.usage       = MTLTextureUsageRenderTarget;
    textureDescriptor.storageMode = MTLStorageModeMemoryless;

    if(AAPLNumSamples > 1)
    {
        textureDescriptor.sampleCount = AAPLNumSamples;
        textureDescriptor.textureType = MTLTextureType2DMultisample;
        textureDescriptor.pixelFormat = view.colorPixelFormat;

        id<MTLTexture> msaaColorTexture = [_device newTextureWithDescriptor:textureDescriptor];

        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].texture = msaaColorTexture;
    }
    else
    {
        textureDescriptor.textureType = MTLTextureType2D;
    }

    // Create depth buffer texture for depth testing
    {
        textureDescriptor.pixelFormat = AAPLDepthBufferPixelFormat;

        id<MTLTexture> depthBufferTexture = [_device newTextureWithDescriptor:textureDescriptor];

        _viewRenderPassDescriptor.depthAttachment.texture = depthBufferTexture;
    }

    // Create depth data texture to determine min max depth for each tile
    {
        textureDescriptor.pixelFormat = AAPLDepthDataPixelFormat;

        id<MTLTexture> depthDataTexture = [_device newTextureWithDescriptor:textureDescriptor];
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].texture = depthDataTexture;
    }
}

/// Draw the mesh objects with the given render command encoder.
- (void)drawMeshes:(id<MTLRenderCommandEncoder>)renderEncoder
{
    for (__unsafe_unretained AAPLMesh *mesh in _meshes)
    {
        __unsafe_unretained MTKMesh *metalKitMesh = mesh.metalKitMesh;

        // Set the mesh's vertex buffers.
        for (NSUInteger bufferIndex = 0; bufferIndex < metalKitMesh.vertexBuffers.count; bufferIndex++)
        {
            __unsafe_unretained MTKMeshBuffer *vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex];
            if((NSNull*)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        // Draw each submesh of the mesh.
        for(AAPLSubmesh *submesh in mesh.submeshes)
        {
            // Set any textures that you read or sample in the render pipeline.
            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexBaseColor]
                                      atIndex:AAPLTextureIndexBaseColor];

            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexNormal]
                                      atIndex:AAPLTextureIndexNormal];

            [renderEncoder setFragmentTexture:submesh.textures[AAPLTextureIndexSpecular]
                                      atIndex:AAPLTextureIndexSpecular];

            MTKSubmesh *metalKitSubmesh = submesh.metalKitSubmmesh;

            [renderEncoder drawIndexedPrimitives:metalKitSubmesh.primitiveType
                                      indexCount:metalKitSubmesh.indexCount
                                       indexType:metalKitSubmesh.indexType
                                     indexBuffer:metalKitSubmesh.indexBuffer.buffer
                               indexBufferOffset:metalKitSubmesh.indexBuffer.offset];
        }
    }
}

/// Called whenever the view needs to render content.
- (void) drawInMTKView:(nonnull MTKView *)view
{
    // Wait to ensure only `AAPLMaxBuffersInFlight` are getting proccessed by any stage in the
    //   Metal pipeline (app, Metal, drivers, GPU, etc.).
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Create a new command buffer for each render pass to the current drawable.
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Add a completion hander that signals `_inFlightSemaphore` when Metal and the GPU have
    //   fully finished proccssing the commands encoded this frame. This callback indicates when
    //   the dynamic buffers written in this frame are no longer be needed by Metal and the GPU.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
    {
        dispatch_semaphore_signal(block_sema);
    }];

    [self updateFrameState];

    // Check if there is a drawable to render content to.
    if(view.currentDrawable != nil)
    {
        if(AAPLNumSamples > 1)
        {
            _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].resolveTexture =
            view.currentDrawable.texture;
        }
        else
        {
            _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].texture =
            view.currentDrawable.texture;
        }

        // Create a render command encoder to render to the drawable.
        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_viewRenderPassDescriptor];

        [renderEncoder setCullMode:MTLCullModeBack];

        // Render scene to depth buffer only. You later use this data to determine the minimum and
        // maximum depth values of each tile.
        [renderEncoder pushDebugGroup:@"Depth Pre-Pass"];
        [renderEncoder setRenderPipelineState:_depthPrePassPipelineState];
        [renderEncoder setDepthStencilState:_defaultDepthState];
        [renderEncoder setVertexBuffer:_frameDataBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [self drawMeshes:renderEncoder];
        [renderEncoder popDebugGroup];

        // Calculate light bins.
        [renderEncoder pushDebugGroup:@"Calculate Light Bins"];
        [renderEncoder setRenderPipelineState:_lightBinCreationPipelineState];
        [renderEncoder setThreadgroupMemoryLength:AAPLTileDataSize offset:AAPLThreadgroupBufferSize atIndex:AAPLThreadgroupBufferIndexTileData];
        [renderEncoder dispatchThreadsPerTile:MTLSizeMake(AAPLTileWidth, AAPLTileHeight, 1)];
        [renderEncoder popDebugGroup];
                // Perform tile culling, to minimize the number of lights rendered per tile.
        [renderEncoder pushDebugGroup:@"Prepare Light Lists"];
        [renderEncoder setRenderPipelineState:_lightCullingPipelineState];
        [renderEncoder setThreadgroupMemoryLength:AAPLThreadgroupBufferSize offset:0 atIndex:AAPLThreadgroupBufferIndexLightList];
        [renderEncoder setThreadgroupMemoryLength:AAPLTileDataSize offset:AAPLThreadgroupBufferSize atIndex:AAPLThreadgroupBufferIndexTileData];
        [renderEncoder setTileBuffer:_frameDataBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setTileBuffer:_lightEyePositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [renderEncoder dispatchThreadsPerTile:MTLSizeMake(AAPLTileWidth,AAPLTileHeight,1)];
        [renderEncoder popDebugGroup];

        // Render objects with lighting.
        [renderEncoder pushDebugGroup:@"Render Forward Lighting"];
        [renderEncoder setRenderPipelineState:_forwardLightingPipelineState];
        [renderEncoder setDepthStencilState:_relaxedDepthState];
        [renderEncoder setVertexBuffer:_frameDataBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setFragmentBuffer:_frameDataBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setFragmentBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
        [renderEncoder setFragmentBuffer:_lightWorldPositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [self drawMeshes:renderEncoder];
        [renderEncoder popDebugGroup];

        // Draw fairies.
        [renderEncoder pushDebugGroup:@"Draw Fairies"];
        [renderEncoder setRenderPipelineState:_fairyPipelineState];
        [renderEncoder setDepthStencilState:_defaultDepthState];
        [renderEncoder setVertexBuffer:_frameDataBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setVertexBuffer:_fairy offset:0 atIndex:AAPLBufferIndexMeshPositions];
        [renderEncoder setVertexBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
        [renderEncoder setVertexBuffer:_lightWorldPositions[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:AAPLNumFairyVertices instanceCount:AAPLNumLights];
        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

    }

    // Schedule a presentation for the current drawable, after the framebuffer is complete.
    [commandBuffer presentDrawable:view.currentDrawable];

    // Finalize rendering here and send the command buffer to the GPU.
    [commandBuffer commit];
}

@end

