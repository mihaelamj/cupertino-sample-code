  /*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of renderer class which performs Metal setup and per frame rendering
*/

@import simd;
@import ModelIO;
@import MetalKit;

#include <stdlib.h>

#import "AAPLRenderer.h"
#import "AAPLMesh.h"
#import "AAPLMathUtilities.h"

#import "AAPLShaderTypes.h"

// The max number of command buffers in flight
static const NSUInteger AAPLMaxFramesInFlight = 3;

// Number of vertices in our 2D fairy model
static const NSUInteger AAPLNumFairyVertices = 7;

// 30% of lights are around the tree
// 40% of lights are on the ground inside the columns
// 30% of lights are around the outside of the columns
static const NSUInteger AAPLTreeLights   = 0                 + 0.30 * AAPLNumLights;
static const NSUInteger AAPLGroundLights = AAPLTreeLights    + 0.40 * AAPLNumLights;
static const NSUInteger AAPLColumnLights = AAPLGroundLights  + 0.30 * AAPLNumLights;

// Main class performing the rendering
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;

    // Vertex descriptor for models loaded with MetalKit
    MTLVertexDescriptor *_defaultVertexDescriptor;

    id<MTLCommandQueue> _commandQueue;

    // Pipeline states
    id <MTLRenderPipelineState> _GBufferPipelineState;
    id <MTLRenderPipelineState> _fairyPipelineState;
    id <MTLRenderPipelineState> _skyboxPipelineState;
    id <MTLRenderPipelineState> _shadowGenPipelineState;
    id <MTLRenderPipelineState> _lightMaskPipelineState;
    id <MTLRenderPipelineState> _directionalLightPipelineState;

    // Depth Stencil states
    id <MTLDepthStencilState> _lightMaskDepthStencilState;
    id <MTLDepthStencilState> _directionLightDepthStencilState;
    id <MTLDepthStencilState> _GBufferDepthStencilState;
    id <MTLDepthStencilState> _shadowDepthStencilState;

    // Render Pass descriptor for shadow generation reused each frame
    MTLRenderPassDescriptor *_shadowRenderPassDescriptor;

    // Texture to create smooth round particles
    id<MTLTexture> _fairyMap;

    // Projection matrix calculated as a function of view size
    matrix_float4x4 _projection_matrix;

    matrix_float4x4 _shadowProjectionMatrix;

    // Current frame number rendering
    NSUInteger _frameNumber;

    // Array of meshes loaded from the model file
    NSArray<AAPLMesh *> *_meshes;

    // Mesh for sphere use to render the skybox
    MTKMesh *_skyMesh;

    // Vertex descriptor for models loaded with MetalKit
    MTLVertexDescriptor *_skyVertexDescriptor;

    // Texture for skybox
    id <MTLTexture> _skyMap;

    // Mesh buffer for fairies
    id<MTLBuffer> _fairy;

    // Light positions before transformation to positions in current frame
    NSData *_originalLightPositions;
}

/// Init common assets and Metal objects
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super init];
    if(self)
    {
        _device = view.device;
        _view = view;

        _inFlightSemaphore = dispatch_semaphore_create(AAPLMaxFramesInFlight);
    }

    return self;
}

- (id<MTLLibrary>)shaderLibrary
{
    NSURL *libraryURL;

// macOS 11 uses shader using Metal Shading Language 2.3 which supports programmable
// blending on Apple Silicon Macs
#ifdef TARGET_MACOS
    if (@available(macOS 11, *))
    {
        libraryURL = [[NSBundle mainBundle] URLForResource:@"MSL23Shaders" withExtension:@"metallib"];
    }
    else
#endif
    {
        libraryURL = [[NSBundle mainBundle] URLForResource:@"MSL20Shaders" withExtension:@"metallib"];
    }

    NSError *error;

    id <MTLLibrary> shaderLibrary = [_device newLibraryWithURL:libraryURL error:&error];

    NSAssert(shaderLibrary, @"Failed to load Metal shader library (%@): %@", libraryURL, error);

    return shaderLibrary;
}

/// Create Metal render state objects
- (void)loadMetal
{
    // Create and load the basic Metal state objects
    NSError* error;

    NSLog(@"Selected Device: %@", _view.device.name);

    // C Arrays cannot be properties in ObjectiveC, only NSArrays can be properties.   Initilize
    // the frame data and light position buffers and put them into CArrays.  Then iniilize the
    // iVars for the NSArray properties with the CArrays.
    id<MTLBuffer> frameDataBuffersCArray[AAPLMaxFramesInFlight];
    id<MTLBuffer> lightPositionsCArray[AAPLMaxFramesInFlight];

    for(NSUInteger i = 0; i < AAPLMaxFramesInFlight; i++)
    {
        // Indicate shared storage so that both the  CPU can access the buffers
        const MTLResourceOptions storageMode = MTLResourceStorageModeShared;

        frameDataBuffersCArray[i] = [_device newBufferWithLength:sizeof(AAPLFrameData)
                                                  options:storageMode];

        frameDataBuffersCArray[i].label = [NSString stringWithFormat:@"FrameDataBuffer%lu", i];

        lightPositionsCArray[i] = [_device newBufferWithLength:sizeof(vector_float4)*AAPLNumLights
                                                       options:storageMode];

        lightPositionsCArray[i].label = [NSString stringWithFormat:@"LightPositions%lu", i];
    }

    _frameDataBuffers = [[NSArray alloc] initWithObjects:frameDataBuffersCArray count:AAPLMaxFramesInFlight];

    _lightPositions = [[NSArray alloc] initWithObjects:lightPositionsCArray count:AAPLMaxFramesInFlight];

    id <MTLLibrary> shaderLibrary = self.shaderLibrary;

    #pragma mark Mesh vertex descriptor setup
    _defaultVertexDescriptor = [MTLVertexDescriptor new];

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

    // Tangents
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].offset = 16;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeTangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Bitangents
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].format = MTLVertexFormatHalf4;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].offset = 24;
    _defaultVertexDescriptor.attributes[AAPLVertexAttributeBitangent].bufferIndex = AAPLBufferIndexMeshGenerics;

    // Position Buffer Layout
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    // Generic Attribute Buffer Layout
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 32;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepRate = 1;
    _defaultVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    _colorTargetPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    _depthStencilTargetPixelFormat = MTLPixelFormatDepth32Float_Stencil8;

    _view.colorPixelFormat = _colorTargetPixelFormat;
    _view.depthStencilPixelFormat = _depthStencilTargetPixelFormat;

    _albedo_specular_GBufferFormat = MTLPixelFormatRGBA8Unorm_sRGB;
    _normal_shadow_GBufferFormat = MTLPixelFormatRGBA8Snorm;
    _depth_GBufferFormat = MTLPixelFormatR32Float;

    #pragma mark GBuffer render pipeline setup
    {
        {
            id <MTLFunction> GBufferVertexFunction = [shaderLibrary newFunctionWithName:@"gbuffer_vertex"];
            id <MTLFunction> GBufferFragmentFunction = [shaderLibrary newFunctionWithName:@"gbuffer_fragment"];

            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];

            renderPipelineDescriptor.label = @"Geometry buffer render pipeline";
            renderPipelineDescriptor.vertexDescriptor = _defaultVertexDescriptor;

            // The single pass deferred renderer leaves the drawable attached when constucting
            // GBuffer creation, so the render pipeline must have the drawable's pixel format set.
            if(_singlePassDeferred)
            {
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _view.colorPixelFormat;
            }
            else
            {
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = MTLPixelFormatInvalid;
            }

            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = _albedo_specular_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat = _normal_shadow_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = _depth_GBufferFormat;
            renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
            renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;

            renderPipelineDescriptor.vertexFunction = GBufferVertexFunction;
            renderPipelineDescriptor.fragmentFunction = GBufferFragmentFunction;
            _GBufferPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                                error:&error];

            NSAssert(_GBufferPipelineState, @"Failed to create GBuffer render pipeline state: %@", error);
        }

        #pragma mark GBuffer depth state setup
        {
#if LIGHT_STENCIL_CULLING
            MTLStencilDescriptor *stencilStateDesc = [MTLStencilDescriptor new];
            stencilStateDesc.stencilCompareFunction = MTLCompareFunctionAlways;
            stencilStateDesc.stencilFailureOperation = MTLStencilOperationKeep;
            stencilStateDesc.depthFailureOperation = MTLStencilOperationKeep;
            stencilStateDesc.depthStencilPassOperation = MTLStencilOperationReplace;
            stencilStateDesc.readMask = 0x0;
            stencilStateDesc.writeMask = 0xFF;
#else
            MTLStencilDescriptor *stencilStateDesc = nil;
#endif
            MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
            depthStencilDesc.label =  @"Geometry buffer depth/stencil";
            depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
            depthStencilDesc.depthWriteEnabled = YES;
            depthStencilDesc.frontFaceStencil = stencilStateDesc;
            depthStencilDesc.backFaceStencil = stencilStateDesc;

            _GBufferDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
        }
    }

    // Setup render state to apply directional light and shadow in final pass
    {
        #pragma mark Directional lighting render pipeline setup
        {
            id <MTLFunction> directionalVertexFunction = [shaderLibrary newFunctionWithName:@"deferred_direction_lighting_vertex"];

            id <MTLFunction> directionalFragmentFunction;

            if(_singlePassDeferred)
            {
                directionalFragmentFunction =
                    [shaderLibrary newFunctionWithName:@"deferred_directional_lighting_fragment_single_pass"];
            }
            else
            {
                directionalFragmentFunction =
                    [shaderLibrary newFunctionWithName:@"deferred_directional_lighting_fragment_traditional"];
            }

            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];

            renderPipelineDescriptor.label = @"Deferred Directional Lighting";
            renderPipelineDescriptor.vertexDescriptor = nil;
            renderPipelineDescriptor.vertexFunction = directionalVertexFunction;
            renderPipelineDescriptor.fragmentFunction = directionalFragmentFunction;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _view.colorPixelFormat;

            if(_singlePassDeferred)
            {
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = _albedo_specular_GBufferFormat;
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat = _normal_shadow_GBufferFormat;
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = _depth_GBufferFormat;
            }

            renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
            renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;

            _directionalLightPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                                     error:&error];

            NSAssert(_directionalLightPipelineState,
                     @"Failed to create directional light render pipeline state: %@", error);

        }

        #pragma mark Directional lighting mask depth stencil state setup
        {
#if LIGHT_STENCIL_CULLING
            // Stencil state setup so direction lighting fragment shader only executed on pixels
            // drawn in GBuffer stage (i.e. mask out the background/sky)
            MTLStencilDescriptor *stencilStateDesc = [MTLStencilDescriptor new];
            stencilStateDesc.stencilCompareFunction = MTLCompareFunctionEqual;
            stencilStateDesc.stencilFailureOperation = MTLStencilOperationKeep;
            stencilStateDesc.depthFailureOperation = MTLStencilOperationKeep;
            stencilStateDesc.depthStencilPassOperation = MTLStencilOperationKeep;
            stencilStateDesc.readMask = 0xFF;
            stencilStateDesc.writeMask = 0x0;
#else
            MTLStencilDescriptor *stencilStateDesc = nil;
#endif
            MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
            depthStencilDesc.label = @"Deferred Directional Lighting";
            depthStencilDesc.depthWriteEnabled = NO;
            depthStencilDesc.depthCompareFunction = MTLCompareFunctionAlways;
            depthStencilDesc.frontFaceStencil = stencilStateDesc;
            depthStencilDesc.backFaceStencil = stencilStateDesc;

            _directionLightDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
        }
    }

    #pragma mark Fairy billboard render pipeline setup
    {
        id <MTLFunction> fairyVertexFunction = [shaderLibrary newFunctionWithName:@"fairy_vertex"];
        id <MTLFunction> fairyFragmentFunction = [shaderLibrary newFunctionWithName:@"fairy_fragment"];

        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];

        renderPipelineDescriptor.label = @"Fairy Drawing";
        renderPipelineDescriptor.vertexDescriptor = nil;
        renderPipelineDescriptor.vertexFunction = fairyVertexFunction;
        renderPipelineDescriptor.fragmentFunction = fairyFragmentFunction;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _view.colorPixelFormat;

        // Because iOS renderer can perform GBuffer pass in final pass, any pipeline rendering in
        // the final pass must take the GBuffers into account
        if(_singlePassDeferred)
        {
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = _albedo_specular_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat = _normal_shadow_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = _depth_GBufferFormat;
        }

        renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;
        renderPipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOne;
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOne;

        _fairyPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                      error:&error];

        NSAssert(_fairyPipelineState, @"Failed to create fairy render pipeline state: %@", error);
    }

    #pragma mark Sky render pipeline setup
    {
        _skyVertexDescriptor = [MTLVertexDescriptor new];
        _skyVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
        _skyVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
        _skyVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;
        _skyVertexDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = 12;
        _skyVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
        _skyVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 0;
        _skyVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLBufferIndexMeshGenerics;
        _skyVertexDescriptor.layouts[AAPLBufferIndexMeshGenerics].stride = 12;

        id <MTLFunction> skyboxVertexFunction = [shaderLibrary newFunctionWithName:@"skybox_vertex"];
        id <MTLFunction> skyboxFragmentFunction = [shaderLibrary newFunctionWithName:@"skybox_fragment"];

        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.label = @"Sky";
        renderPipelineDescriptor.vertexDescriptor = _skyVertexDescriptor;
        renderPipelineDescriptor.vertexFunction = skyboxVertexFunction;
        renderPipelineDescriptor.fragmentFunction = skyboxFragmentFunction;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _view.colorPixelFormat;

        if(_singlePassDeferred)
        {
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = _albedo_specular_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat = _normal_shadow_GBufferFormat;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = _depth_GBufferFormat;
        }

        renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;

        _skyboxPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                      error:&error];

        NSAssert(_skyboxPipelineState, @"Failed to create skybox render pipeline state: %@", error);
    }

    #pragma mark Post lighting depth state setup
    {
        MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
        depthStencilDesc.label = @"Less -Writes";
        depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthStencilDesc.depthWriteEnabled = NO;

        _dontWriteDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
    }

    // Setup objects for shadow pass
    {
        MTLPixelFormat shadowMapPixelFormat = MTLPixelFormatDepth32Float;

        if (@available( iOS 13, tvOS 13, *))
        {
            shadowMapPixelFormat = MTLPixelFormatDepth16Unorm;
        }

        #pragma mark Shadow pass render pipeline setup
        {
            id <MTLFunction> shadowVertexFunction = [shaderLibrary newFunctionWithName:@"shadow_vertex"];

            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
            renderPipelineDescriptor.label = @"Shadow Gen";
            renderPipelineDescriptor.vertexDescriptor = nil;
            renderPipelineDescriptor.vertexFunction = shadowVertexFunction;
            renderPipelineDescriptor.fragmentFunction = nil;
            renderPipelineDescriptor.depthAttachmentPixelFormat = shadowMapPixelFormat;

            _shadowGenPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                              error:&error];

        }

        #pragma mark Shadow pass depth state setup
        {
            MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
            depthStencilDesc.label = @"Shadow Gen";
#if REVERSE_DEPTH
            depthStencilDesc.depthCompareFunction = MTLCompareFunctionGreaterEqual;
#else
            depthStencilDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
#endif
            depthStencilDesc.depthWriteEnabled = YES;
            _shadowDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
        }

        #pragma mark Shadow map setup
        {
            MTLTextureDescriptor *shadowTextureDesc =
                [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:shadowMapPixelFormat
                                                                   width:2048
                                                                  height:2048
                                                               mipmapped:NO];

            shadowTextureDesc.resourceOptions = MTLResourceStorageModePrivate;
            shadowTextureDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

            _shadowMap = [_device newTextureWithDescriptor:shadowTextureDesc];
            _shadowMap.label = @"Shadow Map";
        }


        #pragma mark Shadow render pass descriptor setup
        // Create render pass descriptor to reuse for shadow pass
        {
            _shadowRenderPassDescriptor = [MTLRenderPassDescriptor new];
            _shadowRenderPassDescriptor.depthAttachment.texture = _shadowMap;
            _shadowRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
            _shadowRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
            _shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
        }

        // Calculate projection matrix to render shadows
        {
            _shadowProjectionMatrix = matrix_ortho_left_hand(-53, 53, -33, 53, -53, 53);
        }
    }

#if LIGHT_STENCIL_CULLING
    // Setup objects for point light mask rendering
    {

        #pragma mark Light mask render pipeline state setup
        {
            id <MTLFunction> lightMaskVertex = [shaderLibrary newFunctionWithName:@"light_mask_vertex"];

            MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
            renderPipelineDescriptor.label = @"Point Light Mask";
            renderPipelineDescriptor.vertexDescriptor = nil;
            renderPipelineDescriptor.vertexFunction = lightMaskVertex;
            renderPipelineDescriptor.fragmentFunction = nil;
            renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _view.colorPixelFormat;

            if(_singlePassDeferred)
            {
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = _albedo_specular_GBufferFormat;
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat = _normal_shadow_GBufferFormat;
                renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat = _depth_GBufferFormat;
            }

            renderPipelineDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
            renderPipelineDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;
            
            _lightMaskPipelineState =
                [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                        error:&error];
        }

        #pragma mark Light mask depth stencil state setup
        {
            MTLStencilDescriptor *stencilStateDesc = [MTLStencilDescriptor new];
            stencilStateDesc.stencilCompareFunction = MTLCompareFunctionAlways;
            stencilStateDesc.stencilFailureOperation = MTLStencilOperationKeep;
            stencilStateDesc.depthFailureOperation = MTLStencilOperationIncrementClamp;
            stencilStateDesc.depthStencilPassOperation = MTLStencilOperationKeep;
            stencilStateDesc.readMask = 0x0;
            stencilStateDesc.writeMask = 0xFF;
            MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
            depthStencilDesc.label = @"Point Light Mask";
            depthStencilDesc.depthWriteEnabled = NO;
            depthStencilDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
            depthStencilDesc.frontFaceStencil = stencilStateDesc;
            depthStencilDesc.backFaceStencil = stencilStateDesc;

            _lightMaskDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
        }
    }
#endif // END LIGHT_STENCIL_CULLING

    #pragma mark Point light depth state setup
    {
#if LIGHT_STENCIL_CULLING
        MTLStencilDescriptor *stencilStateDesc = [MTLStencilDescriptor new];
        stencilStateDesc.stencilCompareFunction = MTLCompareFunctionLess;
        stencilStateDesc.stencilFailureOperation = MTLStencilOperationKeep;
        stencilStateDesc.depthFailureOperation = MTLStencilOperationKeep;
        stencilStateDesc.depthStencilPassOperation = MTLStencilOperationKeep;
        stencilStateDesc.readMask = 0xFF;
        stencilStateDesc.writeMask = 0x0;
#else  // IF NOT LIGHT_STENCIL_CULLING
        MTLStencilDescriptor *stencilStateDesc = nil;
#endif // END NOT LIGHT_STENCIL_CULLING
        MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
        depthStencilDesc.depthWriteEnabled = NO;
        depthStencilDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStencilDesc.frontFaceStencil = stencilStateDesc;
        depthStencilDesc.backFaceStencil = stencilStateDesc;
        depthStencilDesc.label = @"Point Light";

        _pointLightDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
    }

    // Create the command queue
    _commandQueue = [_device newCommandQueue];
}

- (void)loadScene
{
    [self loadAssets];
    [self populateLights];
}

/// Load models/textures, etc.
- (void)loadAssets
{
    // Create and load assets into Metal objects including meshes and textures
    NSError *error = nil;

    #pragma mark Load meshes from model file
    {
        // Create a ModelIO vertexDescriptor so that the format/layout of the ModelIO mesh vertices
        //   cah be made to match Metal render pipeline's vertex descriptor layout
        MDLVertexDescriptor *modelIOVertexDescriptor =
            MTKModelIOVertexDescriptorFromMetal(_defaultVertexDescriptor);

        // Indicate how each Metal vertex descriptor attribute maps to each ModelIO attribute
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

        NSAssert(_meshes, @"Could not create meshes from model file %@: %@", modelFileURL.absoluteString, error);
    }

    #pragma mark Setup buffer with attributes for each point light/fairy
    {
        _lightsData = [_device newBufferWithLength:sizeof(AAPLPointLight)*AAPLNumLights options:0];
        _lightsData.label = @"LightData";

        NSAssert(_lightsData, @"Could not create lights data buffer");
    }

    #pragma mark Setup quad for fullscreen composition drawing
    {
        static const AAPLSimpleVertex QuadVertices[] =
        {
            { { -1.0f,  -1.0f, } },
            { { -1.0f,   1.0f, } },
            { {  1.0f,  -1.0f, } },

            { {  1.0f,  -1.0f, } },
            { { -1.0f,   1.0f, } },
            { {  1.0f,   1.0f, } },
        };

        _quadVertexBuffer = [_device newBufferWithBytes:QuadVertices
                                                 length:sizeof(QuadVertices)
                                               options:0];

        _quadVertexBuffer.label = @"Quad Vertices";
    }

    #pragma mark Setup 2D circle mesh for fairy billboards
    {
        AAPLSimpleVertex fairyVertices[AAPLNumFairyVertices];
        const float angle = 2*M_PI/(float)AAPLNumFairyVertices;
        for(int vtx = 0; vtx < AAPLNumFairyVertices; vtx++)
        {
            int point = (vtx%2) ? (vtx+1)/2 : -vtx/2;
            vector_float2 position = {sin(point*angle), cos(point*angle)};
            fairyVertices[vtx].position = position;
        }

        _fairy = [_device newBufferWithBytes:fairyVertices length:sizeof(fairyVertices) options:0];

        _fairy.label = @"Fairy Vertices";
    }

    #pragma mark Setup icosahedron mesh for fairy light volumes
    {
        MTKMeshBufferAllocator *bufferAllocator =
            [[MTKMeshBufferAllocator alloc] initWithDevice:_device];

        const double unitInscribe = sqrtf(3.0) / 12.0 * (3.0 + sqrtf(5.0));

        MDLMesh *icosahedronMDLMesh = [MDLMesh newIcosahedronWithRadius:1/unitInscribe inwardNormals:NO allocator:bufferAllocator];

        MDLVertexDescriptor *icosahedronDescriptor = [[MDLVertexDescriptor alloc] init];
        icosahedronDescriptor.attributes[AAPLVertexAttributePosition].name = MDLVertexAttributePosition;
        icosahedronDescriptor.attributes[AAPLVertexAttributePosition].format = MDLVertexFormatFloat4;
        icosahedronDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
        icosahedronDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLBufferIndexMeshPositions;

        icosahedronDescriptor.layouts[AAPLBufferIndexMeshPositions].stride = sizeof(vector_float4);

        // Set the vertex descriptor to relayout vertices
        icosahedronMDLMesh.vertexDescriptor = icosahedronDescriptor;

        _icosahedronMesh = [[MTKMesh alloc] initWithMesh:icosahedronMDLMesh
                                                 device:_device
                                                  error:&error];

        NSAssert(_icosahedronMesh, @"Could not create mesh: %@", error);
    }

    #pragma mark Setup sphere mesh for skybox
    {
        MTKMeshBufferAllocator *bufferAllocator =
            [[MTKMeshBufferAllocator alloc] initWithDevice:_device];

        MDLMesh *sphereMDLMesh = [MDLMesh newEllipsoidWithRadii:150
                                                 radialSegments:20
                                               verticalSegments:20
                                                   geometryType:MDLGeometryTypeTriangles
                                                  inwardNormals:NO
                                                     hemisphere:NO
                                                      allocator:bufferAllocator];

        MDLVertexDescriptor *sphereDescriptor = MTKModelIOVertexDescriptorFromMetal(_skyVertexDescriptor);
        sphereDescriptor.attributes[AAPLVertexAttributePosition].name = MDLVertexAttributePosition;
        sphereDescriptor.attributes[AAPLVertexAttributeNormal].name   = MDLVertexAttributeNormal;

        // Set the vertex descriptor to relayout vertices
        sphereMDLMesh.vertexDescriptor = sphereDescriptor;

        _skyMesh = [[MTKMesh alloc] initWithMesh:sphereMDLMesh
                                             device:_device
                                              error:&error];

        NSAssert(_skyMesh, @"Could not create mesh: %@", error);
    }

    #pragma mark Load textures for non-mesh assets
    {
        MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

        NSDictionary *textureLoaderOptions =
        @{
          MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
          MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate),
          };

        _skyMap = [textureLoader newTextureWithName:@"SkyMap"
                                        scaleFactor:1.0
                                             bundle:nil
                                            options:textureLoaderOptions
                                              error:&error];

        NSAssert(_skyMap, @"Could not load sky texture: %@", error);

        _skyMap.label = @"Sky Map";

        _fairyMap = [textureLoader newTextureWithName:@"FairyMap"
                                          scaleFactor:1.0
                                               bundle:nil
                                              options:textureLoaderOptions
                                                error:&error];

        NSAssert(_fairyMap, @"Could not load fairy texture: %@", error);

        _fairyMap.label = @"Fairy Map";
    }
}

/// Initialize light positions and colors
- (void)populateLights
{
    AAPLPointLight *light_data = (AAPLPointLight*)[_lightsData contents];

    NSMutableData * originalLightPositions =  [[NSMutableData alloc] initWithLength:_lightPositions[0].length];

    _originalLightPositions = originalLightPositions;

    vector_float4 *light_position = (vector_float4*)originalLightPositions.mutableBytes;

    srandom(0x134e5348);

    for(NSUInteger lightId = 0; lightId < AAPLNumLights; lightId++)
    {
        float distance = 0;
        float height = 0;
        float angle = 0;
        float speed = 0;

        if(lightId < AAPLTreeLights)
        {
            distance = random_float(38,42);
            height = random_float(0,1);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.003,0.014);
        }
        else if(lightId < AAPLGroundLights)
        {
            distance = random_float(140,260);
            height = random_float(140,150);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.006,0.027);
            speed *= (random()%2)*2-1;
        }
        else if(lightId < AAPLColumnLights)
        {
            distance = random_float(365,380);
            height = random_float(150,190);
            angle = random_float(0, M_PI*2);
            speed = random_float(0.004,0.014);
            speed *= (random()%2)*2-1;
        }

        speed *= .5;
        *light_position = (vector_float4){ distance*sinf(angle),height,distance*cosf(angle),1};
        light_data->light_radius = random_float(25,35)/10.0;
        light_data->light_speed  = speed;

        int colorId = random()%3;
        if( colorId == 0) {
            light_data->light_color = (vector_float3){random_float(4,6),random_float(0,4),random_float(0,4)};
        } else if ( colorId == 1) {
            light_data->light_color = (vector_float3){random_float(0,4),random_float(4,6),random_float(0,4)};
        } else {
            light_data->light_color = (vector_float3){random_float(0,4),random_float(0,4),random_float(4,6)};
        }

        light_data++;
        light_position++;
    }
}

/// Update light positions
- (void)updateLights:(matrix_float4x4)modelViewMatrix
{
    AAPLPointLight *lightData = (AAPLPointLight*)((char*)[_lightsData contents]);

    vector_float4 *currentBuffer =
        (vector_float4*) _lightPositions[_frameDataBufferIndex].contents;

    vector_float4 *originalLightPositions =  (vector_float4 *)_originalLightPositions.bytes;

    for(int i = 0; i < AAPLNumLights; i++)
    {
        vector_float4 currentPosition;

        if(i < AAPLTreeLights)
        {
            double lightPeriod = lightData[i].light_speed * _frameNumber;
            lightPeriod += originalLightPositions[i].y;
            lightPeriod -= floor(lightPeriod);  // Get fractional part

            // Use pow to slowly move the light outward as it reaches the branches of the tree
            float r = 1.2 + 10.0 * powf(lightPeriod, 5.0);

            currentPosition.x = originalLightPositions[i].x * r;
            currentPosition.y = 200.0f + lightPeriod * 400.0f;
            currentPosition.z = originalLightPositions[i].z * r;
            currentPosition.w = 1;
        }
        else
        {
            float rotationRadians = lightData[i].light_speed * _frameNumber;
            matrix_float4x4 rotation = matrix4x4_rotation(rotationRadians, 0, 1, 0);
            currentPosition = matrix_multiply(rotation, originalLightPositions[i]);
        }

        currentPosition = matrix_multiply(modelViewMatrix, currentPosition);
        currentBuffer[i] = currentPosition;
    }
}

/// Update application state for the current frame.  This includes upades to state sent to shadesr which change each frame.
- (void)updateSceneState
{
    if(!_view.paused)
    {
        _frameNumber++;
    }

    _frameDataBufferIndex = (_frameDataBufferIndex+1) % AAPLMaxFramesInFlight;

    AAPLFrameData *frameData = (AAPLFrameData*)_frameDataBuffers[_frameDataBufferIndex].contents;

    // Set projection matrix and calculate inverted projection matrix
    frameData->projection_matrix = _projection_matrix;
    frameData->projection_matrix_inverse = matrix_invert(_projection_matrix);

    // Set screen dimensions
    frameData->framebuffer_width = (uint)[_albedo_specular_GBuffer width];
    frameData->framebuffer_height = (uint)[_albedo_specular_GBuffer height];

    frameData->shininess_factor = 1;
    frameData->fairy_specular_intensity = 32;

    float cameraRotationRadians = _frameNumber * 0.0025f + M_PI;

    vector_float3 cameraRotationAxis = {0, 1, 0};
    matrix_float4x4 cameraRotationMatrix = matrix4x4_rotation(cameraRotationRadians, cameraRotationAxis);

    matrix_float4x4 view_matrix = matrix_look_at_left_hand(0, 18, -50,
                                                          0, 5, 0,
                                                          0, 1, 0);

    view_matrix = matrix_multiply(view_matrix, cameraRotationMatrix);

    frameData->view_matrix = view_matrix;

    matrix_float4x4 templeScaleMatrix = matrix4x4_scale(0.1, 0.1, 0.1);
    matrix_float4x4 templeTranslateMatrix = matrix4x4_translation(0, -10, 0);
    matrix_float4x4 templeModelMatrix = matrix_multiply(templeTranslateMatrix, templeScaleMatrix);
    frameData->temple_model_matrix = templeModelMatrix;
    frameData->temple_modelview_matrix = matrix_multiply(frameData->view_matrix, templeModelMatrix);
    frameData->temple_normal_matrix = matrix3x3_upper_left(frameData->temple_modelview_matrix);

    float skyRotation = _frameNumber * 0.005f - (M_PI_4*3);

    vector_float3 skyRotationAxis = {0, 1, 0};
    matrix_float4x4 skyModelMatrix = matrix4x4_rotation(skyRotation, skyRotationAxis);
    frameData->sky_modelview_matrix = matrix_multiply(cameraRotationMatrix, skyModelMatrix);

    // Update directional light color
    vector_float4 sun_color = {0.5, 0.5, 0.5, 1.0};
    frameData->sun_color = sun_color;
    frameData->sun_specular_intensity = 1;

    // Update sun direction in view space
    vector_float4 sunModelPosition = {-0.25, -0.5, 1.0, 0.0};

    vector_float4 sunWorldPosition = matrix_multiply(skyModelMatrix, sunModelPosition);

    vector_float4 sunWorldDirection = -sunWorldPosition;

    frameData->sun_eye_direction = matrix_multiply(view_matrix, sunWorldDirection);

    {
        vector_float4 directionalLightUpVector = {0.0, 1.0, 1.0, 1.0};

        directionalLightUpVector = matrix_multiply(skyModelMatrix, directionalLightUpVector);
        directionalLightUpVector.xyz = vector_normalize(directionalLightUpVector.xyz);

        matrix_float4x4 shadowViewMatrix = matrix_look_at_left_hand(sunWorldDirection.xyz / 10,
                                                                    (vector_float3){0,0,0},
                                                                    directionalLightUpVector.xyz);

        matrix_float4x4 shadowModelViewMatrix = matrix_multiply(shadowViewMatrix, templeModelMatrix);

        frameData->shadow_mvp_matrix = matrix_multiply(_shadowProjectionMatrix, shadowModelViewMatrix);
    }

    {
        // When calculating texture coordinates to sample from shadow map, flip the y/t coordinate and
        // convert from the [-1, 1] range of clip coordinates to [0, 1] range of
        // used for texture sampling
        matrix_float4x4 shadowScale = matrix4x4_scale(0.5f, -0.5f, 1.0);
        matrix_float4x4 shadowTranslate = matrix4x4_translation(0.5, 0.5, 0);
        matrix_float4x4 shadowTransform = matrix_multiply(shadowTranslate, shadowScale);

        frameData->shadow_mvp_xform_matrix = matrix_multiply(shadowTransform, frameData->shadow_mvp_matrix);
    }

    frameData->fairy_size = .4;

    [self updateLights:frameData->temple_modelview_matrix];
}

/// Called whenever view changes orientation or layout is changed
- (void)drawableSizeWillChange:(CGSize)size withGBufferStorageMode:(MTLStorageMode)storageMode
{
    // When reshape is called, update the aspect ratio and projection matrix since the view
    //   orientation or size has changed
    float aspect = size.width / (float)size.height;
    _projection_matrix = matrix_perspective_left_hand(65.0f * (M_PI / 180.0f), aspect, AAPLNearPlane, AAPLFarPlane);

    MTLTextureDescriptor *GBufferTextureDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm_sRGB
                                                           width:size.width
                                                          height:size.height
                                                       mipmapped:NO];

    GBufferTextureDesc.textureType = MTLTextureType2D;
    GBufferTextureDesc.usage |= MTLTextureUsageRenderTarget;
    GBufferTextureDesc.storageMode = storageMode;

    GBufferTextureDesc.pixelFormat = _albedo_specular_GBufferFormat;
    _albedo_specular_GBuffer = [_device newTextureWithDescriptor:GBufferTextureDesc];

    GBufferTextureDesc.pixelFormat = _normal_shadow_GBufferFormat;
    _normal_shadow_GBuffer = [_device newTextureWithDescriptor:GBufferTextureDesc];

    GBufferTextureDesc.pixelFormat = _depth_GBufferFormat;
    _depth_GBuffer = [_device newTextureWithDescriptor:GBufferTextureDesc];
    _albedo_specular_GBuffer.label = @"Albedo + Shadow GBuffer";
    _normal_shadow_GBuffer.label   = @"Normal + Specular GBuffer";
    _depth_GBuffer.label           = @"Depth GBuffer";
}

/// Draw the AAPLMesh objects with the given renderEncoder
- (void) drawMeshes:(nonnull id<MTLRenderCommandEncoder>)renderEncoder
{
    for (__unsafe_unretained AAPLMesh *mesh in _meshes)
    {
        __unsafe_unretained MTKMesh *metalKitMesh = mesh.metalKitMesh;

        // Set mesh's vertex buffers
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

        // Draw each submesh of the mesh
        for(__unsafe_unretained AAPLSubmesh *submesh in mesh.submeshes)
        {
            // Set any textures read/sampled from the render pipeline
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

/// Get a drawable from the view (or hand back an offscreen drawable for buffer examination mode)
- (nullable id <MTLTexture>) currentDrawableTexture
{
    id <MTLTexture> drawableTexture =  _view.currentDrawable.texture;

#if SUPPORT_BUFFER_EXAMINATION
    if(self.bufferExaminationManager.mode)
    {
        drawableTexture = _bufferExaminationManager.offscreenDrawable;;
    }
#endif // SUPPORT_BUFFER_EXAMINATION

    return drawableTexture;
}

/// Perform operations necessary at the beginning of the frame.  Wait on the in flight semaphore,
/// and get a command buffer to encode intial commands for this frame.
- (nonnull id <MTLCommandBuffer>)beginFrame
{
    // Wait to ensure only AAPLMaxFramesInFlight are getting processed by any stage in the Metal
    //   pipeline (App, Metal, Drivers, GPU, etc)
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    [self updateSceneState];

    // Create a new command buffer for beginning of frame
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    return commandBuffer;
}

/// Perform operations necessary to obtain a command buffer for rendering to the drawable.  By
/// endoding commands that are not dependant on the drawable in a separate command buffer, Metal
/// can begin executing encoded commands for the frame (commands from the previous command buffer)
/// before a drawable for this frame becomes avaliable.
- (nonnull id <MTLCommandBuffer>)beginDrawableCommands
{
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    // Add completion hander to signal `_inFlightSemaphore` which indicates that the GPU is no
    // longer accessing the the dynamic buffer written this frame.  When the GPU no longer accesses
    // the buffer, the Renderer can safely overwrite the buffer's data to update data for a future
    // frame.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];

    return commandBuffer;
}

/// Perform cleanup operations including presenting the drawable and committing the command buffer
/// for the current frame.  Also, when enabled, draw buffer examination elements before all this.
- (void)endFrame:(nonnull id <MTLCommandBuffer>) commandBuffer
{

#if SUPPORT_BUFFER_EXAMINATION
    if(self.bufferExaminationManager.mode)
    {
        [self.bufferExaminationManager drawAndPresentBuffersWithCommandBuffer:commandBuffer];
    }
#endif

    id<MTLDrawable> currentDrawable = _view.currentDrawable;

    [commandBuffer addScheduledHandler:^(id<MTLCommandBuffer> _Nonnull commandBuffer) {
        [currentDrawable present];
    }];

    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}

/// Draw to the depth texture from the directional lights point of view to generate the shadow map
- (void)drawShadow:(nonnull id <MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> encoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_shadowRenderPassDescriptor];

    encoder.label = @"Shadow Map Pass";

    [encoder setRenderPipelineState:_shadowGenPipelineState];
    [encoder setDepthStencilState:_shadowDepthStencilState];
    [encoder setCullMode: MTLCullModeBack];
    [encoder setDepthBias:0.015 slopeScale:7 clamp:0.02];

    [encoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];

    [self drawMeshes:encoder];

    [encoder endEncoding];
}

/// Draw to the three textures which compose the GBuffer
- (void)drawGBuffer:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Geometry buffer render pass"];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setRenderPipelineState:_GBufferPipelineState];
    [renderEncoder setDepthStencilState:_GBufferDepthStencilState];
    [renderEncoder setStencilReferenceValue:128];
    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentTexture:_shadowMap atIndex:AAPLTextureIndexShadow];

    [self drawMeshes:renderEncoder];
    [renderEncoder popDebugGroup];
}

/// Draw the directional ("sun") light in deferred pass.  Use stencil buffer to limit execution
/// of the shader to only those pixels that should be lit
- (void)drawDirectionalLightCommon:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setStencilReferenceValue:128];

    [renderEncoder setRenderPipelineState:_directionalLightPipelineState];
    [renderEncoder setDepthStencilState:_directionLightDepthStencilState];
    [renderEncoder setVertexBuffer:_quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];

    // Draw full screen quad
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

/// Render to stencil buffer only to increment stencil on that fragments in front
/// of the backside of each light volume
-(void)drawPointLightMask:(nonnull id<MTLRenderCommandEncoder>)renderEncoder
{
#if LIGHT_STENCIL_CULLING
    [renderEncoder pushDebugGroup:@"Draw Light Mask"];
    [renderEncoder setRenderPipelineState:_lightMaskPipelineState];
    [renderEncoder setDepthStencilState:_lightMaskDepthStencilState];

    [renderEncoder setStencilReferenceValue:128];
    [renderEncoder setCullMode:MTLCullModeFront];

    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setVertexBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
    [renderEncoder setVertexBuffer:_lightPositions[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];

    MTKMeshBuffer *vertexBuffer = _icosahedronMesh.vertexBuffers[AAPLBufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:AAPLBufferIndexMeshPositions];

    MTKSubmesh *icosahedronSubmesh = _icosahedronMesh.submeshes[0];
    [renderEncoder drawIndexedPrimitives:icosahedronSubmesh.primitiveType
                              indexCount:icosahedronSubmesh.indexCount
                               indexType:icosahedronSubmesh.indexType
                             indexBuffer:icosahedronSubmesh.indexBuffer.buffer
                       indexBufferOffset:icosahedronSubmesh.indexBuffer.offset
                           instanceCount:AAPLNumLights];

    [renderEncoder popDebugGroup];
#endif
}

/// Performs operations common to both single-pass and traditional deferred renders for drawing point lights.
/// Called by derived renderer classes  after they have set up any renderer specific specific state
/// (such as setting GBuffer textures with the traditional deferred renderer not needed for the single-pass renderer)
- (void)drawPointLightsCommon:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setDepthStencilState:_pointLightDepthStencilState];

    [renderEncoder setStencilReferenceValue:128];
    [renderEncoder setCullMode:MTLCullModeBack];

    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setVertexBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
    [renderEncoder setVertexBuffer:_lightPositions[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];

    [renderEncoder setFragmentBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
    [renderEncoder setFragmentBuffer:_lightPositions[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];

    MTKMeshBuffer *vertexBuffer = _icosahedronMesh.vertexBuffers[AAPLBufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:AAPLBufferIndexMeshPositions];

    MTKSubmesh *icosahedronSubmesh = _icosahedronMesh.submeshes[0];
    [renderEncoder drawIndexedPrimitives:icosahedronSubmesh.primitiveType
                              indexCount:icosahedronSubmesh.indexCount
                               indexType:icosahedronSubmesh.indexType
                             indexBuffer:icosahedronSubmesh.indexBuffer.buffer
                       indexBufferOffset:icosahedronSubmesh.indexBuffer.offset
                           instanceCount:AAPLNumLights];
}

/// Draw the "fairies" at the center of the point lights with a 2D disk using a texture to perform
/// smooth alpha blending on the edges
- (void)drawFairies:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Draw Fairies"];
    [renderEncoder setRenderPipelineState:_fairyPipelineState];
    [renderEncoder setDepthStencilState:_dontWriteDepthStencilState];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setVertexBuffer:_fairy offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:_lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
    [renderEncoder setVertexBuffer:_lightPositions[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
    [renderEncoder setFragmentTexture:_fairyMap atIndex:AAPLTextureIndexAlpha];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:AAPLNumFairyVertices instanceCount:AAPLNumLights];
    [renderEncoder popDebugGroup];
}

/// Draw the sky dome behind all other geometry (testing against depth buffer generated in
///  GBuffer pass)
- (void)drawSky:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;
{
    [renderEncoder pushDebugGroup:@"Draw Sky"];
    [renderEncoder setRenderPipelineState:_skyboxPipelineState];
    [renderEncoder setDepthStencilState:_dontWriteDepthStencilState];
    [renderEncoder setCullMode:MTLCullModeFront];

    [renderEncoder setVertexBuffer:_frameDataBuffers[_frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
    [renderEncoder setFragmentTexture:_skyMap atIndex:AAPLTextureIndexBaseColor];

    // Set mesh's vertex buffers
    for (NSUInteger bufferIndex = 0; bufferIndex < _skyMesh.vertexBuffers.count; bufferIndex++)
    {
        __unsafe_unretained MTKMeshBuffer *vertexBuffer = _skyMesh.vertexBuffers[bufferIndex];
        if((NSNull*)vertexBuffer != [NSNull null])
        {
            [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                    offset:vertexBuffer.offset
                                   atIndex:bufferIndex];
        }
    }

    MTKSubmesh *sphereSubmesh = _skyMesh.submeshes[0];
    [renderEncoder drawIndexedPrimitives:sphereSubmesh.primitiveType
                              indexCount:sphereSubmesh.indexCount
                               indexType:sphereSubmesh.indexType
                             indexBuffer:sphereSubmesh.indexBuffer.buffer
                       indexBufferOffset:sphereSubmesh.indexBuffer.offset];

    [renderEncoder popDebugGroup];
}

- (id<MTLTexture>)depthStencilTexture
{
    return _view.depthStencilTexture;
}

- (void)drawSceneToView:(nonnull MTKView *)view
{
    assert(!"Only implementation derived class should be executed");
}

- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    assert(!"Only implementation derived class should be executed");
}

#if SUPPORT_BUFFER_EXAMINATION

- (void)validateBufferExaminationMode
{
    assert(!"Only implementation derived class should be executed");
}

#endif

@end
