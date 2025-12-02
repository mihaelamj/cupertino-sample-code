/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation for the renderer class that performs Metal setup and per-frame rendering.
*/

@import simd;
@import MetalKit;

#import "AAPLRenderer.h"
#import "AAPLShaderTypes.h"

/// The number of frames the app allows in flight at any given time.
static const size_t AAPLMaxBuffersInFlight = 3;

/// The number of visibility buffers that's at least one more than the number of frames in flight.
///
/// This avoids a data race condition when the GPU writes into the visibility result buffer while the CPU reads to decide which objects to draw.
static const size_t AAPLNumVisibilityBuffers = 1 + AAPLMaxBuffersInFlight;

/// Defines the red sphere's index in the per-frame object data that the vertex shader references.
static const size_t AAPLRedSphereIndex = 0;

/// Defines the green sphere's index in the per-frame object data that the vertex shader references.
static const size_t AAPLGreenSphereIndex = 1;

/// The app's renderer class that renders each frame.
@implementation AAPLRenderer
{
    /// A semaphore that controls when the app begins drawing a frame.
    dispatch_semaphore_t        _inFlightSemaphore;
    
    /// The GPU device the app uses to create a command queue and resources.
    id<MTLDevice>               _device;
    
    /// The command queue that passes commands to the GPU.
    id<MTLCommandQueue>         _commandQueue;
    
    /// The render encoder the app uses to encode draw commands.
    id<MTLRenderCommandEncoder> _renderEncoder;
    
    /// A render pipeline that configures with the app's vertex and fragment shaders.
    /// The source for these shaders is in the `.metal` shader file.
    id<MTLRenderPipelineState>  _pipelineState;
    
    /// A render pipeline that the app uses for occlusion queries with the depth test.
    /// However, it doesn't use a fragment function or write to the depth buffer.
    id<MTLRenderPipelineState>  _pipelineStateNoRender;
    
    /// The depth stencil state for the rendering pipeline state.
    id<MTLDepthStencilState>    _depthState;
    
    /// The depth stencil state for the non-rendering pipeline state.
    id<MTLDepthStencilState>    _depthStateDisableWrites;
    
    /// A buffer that stores the geometry of the app's 3D spheres.
    id<MTLBuffer>               _sphereVertices;
    
    /// A buffer that stores the indices of the app's 3D spheres.
    id<MTLBuffer>               _sphereIndices;
    size_t                      _sphereIndexCount;
    
    /// A buffer that stores the geometry of the app's 3D proxy geometry.
    id<MTLBuffer>               _icosahedronVertices;
    
    /// A buffer that stores the indices of the app's 3D proxy geometry.
    id<MTLBuffer>               _icosahedronIndices;
    size_t                      _icosahedronIndexCount;

    /// A reference to the buffer that the app uses to draw the current sphere or icosahedron geometry.
    ///
    /// The `setMeshBuffers` and `renderMesh` methods use these members to simplify drawing code.
    id<MTLBuffer>               _curMeshIndexBuffer;
    size_t                      _curMeshIndexCount;
    
    /// A vertex descriptor that defines the layout of a vertex.
    MTLVertexDescriptor*        _mtlVertexDescriptor;
    
    /// An array of buffers that each store data for a frame.
    id<MTLBuffer>               _frameDataBuffer[AAPLMaxBuffersInFlight];
    uint8_t                     _frameDataBufferIndex;
    
    /// An array of buffers that each store the visibility results for a frame.
    id<MTLBuffer>               _visibilityBuffer[AAPLNumVisibilityBuffers];
    size_t                      _visibilityBufferReadIndex;
    size_t                      _visibilityBufferWriteIndex;
    
    /// The most recent visibility result buffer.
    uint64_t*                   _readFromVisibilityResultBuffer;
    
    /// A rendering projection matrix.
    matrix_float4x4             _projectionMatrix;
}

/// Creates a renderer with a MetalKit view.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
    self = [super init];
    if (self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(AAPLMaxBuffersInFlight);
        [self loadMetalWithView:view];
        [self loadAssets];
    }
    
    return self;
}

/// Loads Metal state objects and initializes the renderer's dependent view properties.
- (void)loadMetalWithView:(nonnull MTKView *)view;
{
    NSError *error;
    
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;
    
    // Get vertex and fragment functions.
    id<MTLLibrary>  defaultLibrary   = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction   = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    // Set up a new PSO for the main render pass.
    MTLRenderPipelineDescriptor *pipelineStateDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDesc.label = @"RenderPSO";
    pipelineStateDesc.sampleCount = view.sampleCount;
    pipelineStateDesc.vertexFunction = vertexFunction;
    pipelineStateDesc.fragmentFunction = fragmentFunction;
    pipelineStateDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDesc.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    pipelineStateDesc.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
    NSAssert(_pipelineState, @"Failed to created pipeline state: %@", error);
    
    // Set up a new pipeline state object for the occlusion query. This is the same but without a fragment function because it isn't drawing.
    pipelineStateDesc.label = @"NoRenderPSO";
    pipelineStateDesc.fragmentFunction = nil;
    
    _pipelineStateNoRender = [_device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
    NSAssert(_pipelineStateNoRender, @"Failed to created pipeline state: %@", error);
    
    // Set up a depth state for the main render pass.
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    // Set up a depth state for the occlusion query with no depth writes.
    depthStateDesc.depthWriteEnabled = NO;
    _depthStateDisableWrites = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    // Set up the frame data buffer for storing the matrices.
    for (size_t i = 0; i < AAPLMaxBuffersInFlight; ++i)
    {
        _frameDataBuffer[i] = [_device newBufferWithLength:sizeof(AAPLFrameData)
                                                   options:MTLResourceStorageModeShared];
        _frameDataBuffer[i].label = @"Frame Data Buffer";
    }
    
    // Create a command queue for creating render encoders.
    _commandQueue = [_device newCommandQueue];
    
    // Initialize the visibility result buffers.
    for (size_t i = 0; i < AAPLNumVisibilityBuffers; ++i)
    {
        _visibilityBuffer[i] = [_device newBufferWithLength:AAPLNumObjectsXYZ * sizeof(uint64_t)
                                                    options:MTLResourceStorageModeShared];
        _visibilityBuffer[i].label = @"visibilitybuffer";
    }
}

/// Creates and loads icosahedrons and spheres into metal objects.
- (void)loadAssets
{
    // Create the icosahedron and sphere objects.
    
    /// A sphere's radius that allows plenty of space between spheres with a grid spacing of two units.
    const double sphereRadius = 0.7;

    /// An adjustment factor that scales up the proxy geometry size.
    ///
    /// The sample sets the factor small enough to avoid a "pop in" effect when the spheres move.
    /// In other words, the sphere may not be visible in the current frame, but visible in the next.
    /// For example, a sphere that's moving behind another sphere may cause the occlusion query to return `false`.
    /// This causes the renderer to erroneously omit the sphere in the next frame.
    ///
    /// The app uses a simple approach that sizes up the icosahedrons by an adjustment factor.
    /// Sizing up the icosahedron gives each object extra pixels for the occlusion query to return `true`.
    /// Since the renderer doesn't know exactly where the objects are located on the next frame,
    /// this is like giving each object a little wiggle room.
    /// If the adjustment value is too small, the renderer may not draw objects that are visible in the current frame.
    /// If it's too large, then renderer may draw more spheres that are hidden by nearer spheres.
    /// A lower value of `1` is best for a stationary scene and does not size up the proxy geometry.
    /// A higher value of `8` sizes the proxy geometry significantly and reduces the occlusion query effectiveness.
    const double animationAdjustmentFactor = 4;

    /// An icosahedron size that's large enough to inscribe a sphere.
    ///
    /// The icosahedron radius includes the previous animation adjustment.
    const double icosahedronRadius = animationAdjustmentFactor * sphereRadius;
    
    [self loadIcosahedronWithRadius:icosahedronRadius];
    
    [self loadSphereWithRadius:sphereRadius];
    
    // Set the app control variables to their default values.
    _position = 1.0;
}

/// Creates an icosahedron mesh that inscribes a sphere with a radius.
- (void)loadIcosahedronWithRadius:(double)radius
{
    // A factor that scales up the icosahedron so that it inscribes the sphere with the radius parameter.
    const double factorToInscribeSphere = (3.0 * sqrt(3.0) - sqrt(15.0));
    const double icosahedronEdge = factorToInscribeSphere * radius;
    
    // Set up the icosahedron for a visibility test volume.
    float X = 0.5 * icosahedronEdge;
    float Z = X * (1.0 + sqrtf(5.0)) / 2.0;
    vector_float4 icosahedronVertices [] =
    {
        {  -X, 0.0,   Z, 1.0 },
        {   X, 0.0,   Z, 1.0 },
        {  -X, 0.0,  -Z, 1.0 },
        {   X, 0.0,  -Z, 1.0 },
        { 0.0,   Z,   X, 1.0 },
        { 0.0,   Z,  -X, 1.0 },
        { 0.0,  -Z,   X, 1.0 },
        { 0.0,  -Z,  -X, 1.0 },
        {   Z,   X, 0.0, 1.0 },
        {  -Z,   X, 0.0, 1.0 },
        {   Z,  -X, 0.0, 1.0 },
        {  -Z,  -X, 0.0, 1.0 }
    };
    
    uint32_t icosahedronIndices[] =
    {
        0,  1,  4,
        0,  4,  9,
        9,  4,  5,
        4,  8,  5,
        4,  1,  8,
        8,  1, 10,
        8, 10,  3,
        5,  8,  3,
        5,  3,  2,
        2,  3,  7,
        7,  3, 10,
        7, 10,  6,
        7,  6, 11,
        11,  6,  0,
        0,  6,  1,
        6, 10,  1,
        9, 11,  0,
        9,  2, 11,
        9,  5,  2,
        7, 11,  2
    };
    
    _icosahedronIndexCount = sizeof(icosahedronIndices) / sizeof(uint32_t);
    
    _icosahedronVertices = [_device newBufferWithBytes:icosahedronVertices
                                                length:sizeof(icosahedronVertices)
                                               options:MTLResourceStorageModeShared];
    
    _icosahedronIndices = [_device newBufferWithBytes:icosahedronIndices
                                               length:sizeof(icosahedronIndices)
                                              options:MTLResourceStorageModeShared];
}

/// Creates a sphere mesh with a radius.
- (void) loadSphereWithRadius:(double)radius
{
#if defined(TARGET_IOS) || defined(TARGET_TVOS)
    const uint32_t radialSegments = 32;
    const uint32_t verticalSegments = 32;
#else
    const uint32_t radialSegments = 250;
    const uint32_t verticalSegments = 250;
#endif
    
    // Fill positions and normals.
    {
        const uint32_t vertexCount = 2 + (radialSegments) * (verticalSegments-1);
        const uint32_t vertexBufferSize = vertexCount * sizeof(vector_float4);
        
        _sphereVertices = [_device newBufferWithLength:vertexBufferSize options:MTLResourceStorageModeShared];
        
        const double radialDelta   = 2 * (M_PI / radialSegments);
        const double verticalDelta = (M_PI / verticalSegments);
        
        vector_float4 *positionData = (vector_float4*) _sphereVertices.contents;
        
        vector_float4 position;
        
        position.x = 0;
        position.y = radius;
        position.z = 0;
        position.w = 1.0;
        
        *positionData = position;
        positionData++;
        
        for (ushort verticalSegment = 1; verticalSegment < verticalSegments; verticalSegment++)
        {
            const double verticalPosition = verticalSegment * verticalDelta;
            
            float y = cos(verticalPosition);
            
            for (ushort radialSegment = 0; radialSegment < radialSegments; radialSegment++)
            {
                const double radialPositon = radialSegment * radialDelta;
                
                position.x = radius * sin(verticalPosition) * cos(radialPositon);
                position.y = radius * y;
                position.z = radius * sin(verticalPosition) * sin(radialPositon);
                
                *positionData = position;
                positionData++;
            }
        }
        
        position.x = 0;
        position.y = -radius;
        position.z = 0;
        
        *positionData = position;
    }
    
    // Fill the index buffer.
    {
        _sphereIndexCount = 6 * radialSegments * (verticalSegments-1);
        const size_t indexBufferSize = _sphereIndexCount * sizeof(uint32_t);
        
        _sphereIndices = [_device newBufferWithLength:indexBufferSize options:MTLResourceStorageModeShared];
        uint32_t *indices = (uint32_t *)_sphereIndices.contents;
        
        uint32_t currentIndex = 0;
        
        // Set the indices for the top of the sphere.
        for (ushort phi = 0; phi < radialSegments; phi++)
        {
            if (phi < radialSegments - 1)
            {
                indices[currentIndex++] = 0;
                indices[currentIndex++] = 2 + phi;
                indices[currentIndex++] = 1 + phi;
            }
            else
            {
                indices[currentIndex++] = 0;
                indices[currentIndex++] = 1;
                indices[currentIndex++] = 1 + phi;
            }
        }
        
        // Set the indices for the middle of the sphere.
        for (ushort theta = 0; theta < verticalSegments-2; theta++)
        {
            uint32_t topRight;
            uint32_t topLeft;
            uint32_t bottomRight;
            uint32_t bottomLeft;
            
            for (ushort phi = 0; phi < radialSegments; phi++)
            {
                if (phi < radialSegments - 1)
                {
                    topRight    = 1 + theta * (radialSegments) + phi;
                    topLeft     = 1 + theta * (radialSegments) + (phi + 1);
                    bottomRight = 1 + (theta + 1) * (radialSegments) + phi;
                    bottomLeft  = 1 + (theta + 1) * (radialSegments) + (phi + 1);
                }
                else
                {
                    topRight    = 1 + theta * (radialSegments) + phi;
                    topLeft     = 1 + theta * (radialSegments);
                    bottomRight = 1 + (theta + 1) * (radialSegments) + phi;
                    bottomLeft  = 1 + (theta + 1) * (radialSegments);
                }
                
                indices[currentIndex++] = topRight;
                indices[currentIndex++] = bottomLeft;
                indices[currentIndex++] = bottomRight;
                
                indices[currentIndex++] = topRight;
                indices[currentIndex++] = topLeft;
                indices[currentIndex++] = bottomLeft;
            }
        }
        
        // Set the indices for the bottom of the sphere.
        uint32_t lastIndex = radialSegments * (verticalSegments-1) + 1;
        for (ushort phi = 0; phi < radialSegments; phi++)
        {
            if (phi < radialSegments - 1)
            {
                indices[currentIndex++] = lastIndex;
                indices[currentIndex++] = lastIndex - radialSegments + phi;
                indices[currentIndex++] = lastIndex - radialSegments + phi + 1;
            }
            else
            {
                indices[currentIndex++] = lastIndex;
                indices[currentIndex++] = lastIndex - radialSegments + phi;
                indices[currentIndex++] = lastIndex - radialSegments;
            }
        }
    }
}

#pragma mark Common Rendering Methods

/// Sets the current vertex buffer and stores the index buffer information for rendering.
- (void)setMeshBuffers:(id<MTLBuffer>)vertexBuffer
           indexBuffer:(id<MTLBuffer>)indexBuffer
            indexCount:(size_t)indexCount
{
    _curMeshIndexBuffer = indexBuffer;
    _curMeshIndexCount = indexCount;
    
    [_renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:AAPLBufferIndexPositions];
}

/// Renders a mesh and sets the index of the mesh so the shader can reference its appearance and location data.
- (void)renderMeshWithIndex:(uint32_t)meshIndex
{
    [_renderEncoder setVertexBytes:&meshIndex
                            length:sizeof(uint32_t)
                           atIndex:AAPLBufferIndexMeshIndex];
    [_renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:_curMeshIndexCount
                                indexType:MTLIndexTypeUInt32
                              indexBuffer:_curMeshIndexBuffer
                        indexBufferOffset:0];
}

#pragma mark Mode 1: Fragment Counting

/// Configures the app's state to prepare encoding rendering commands for the first mode, which counts fragments.
- (void)updateFragmentCountingMode
{
    AAPLFrameData* frameData = (_frameDataBuffer[_frameDataBufferIndex]).contents;
    
    // The position for the red sphere is fixed.
    matrix_float4x4 modelViewMatrix = matrix4x4_translation(0.0, 0.0, -6.0);
    frameData->objects[AAPLRedSphereIndex].modelViewMatrix = modelViewMatrix;
    frameData->objects[AAPLRedSphereIndex].modelViewProjMatrix = matrix_multiply(_projectionMatrix, modelViewMatrix);
    frameData->objects[AAPLRedSphereIndex].color = simd_make_float3(1.0f, 0.0f, 0.0f);
    
    // The position for the green sphere is dependent on the `_position` variable.
    // Make the green sphere smaller so that it's inside the red sphere at the center position.
    matrix_float4x4 T = matrix4x4_translation(3.0f * _position, 0.0f, -6.0f);
    matrix_float4x4 S = matrix4x4_scaling(0.7f);
    modelViewMatrix = matrix_multiply(T, S);
    frameData->objects[AAPLGreenSphereIndex].modelViewMatrix = modelViewMatrix;
    frameData->objects[AAPLGreenSphereIndex].modelViewProjMatrix = matrix_multiply(_projectionMatrix, modelViewMatrix);
    frameData->objects[AAPLGreenSphereIndex].color = simd_make_float3(0.0f, 1.0f, 0.0f);
}

/// Encodes a render pass that counts the number of fragments from the green sphere that pass the depth-stencil tests.
- (void)renderFragmentCountingMode
{
    self->_numVisibleFragments = _readFromVisibilityResultBuffer[AAPLGreenSphereIndex];
        
    // Encode the sphere's vertex data.
    [self setMeshBuffers:_sphereVertices indexBuffer:_sphereIndices indexCount:_sphereIndexCount];
    
    // Encode the red sphere mesh for drawing.
    [self renderMeshWithIndex:(uint32_t)AAPLRedSphereIndex];
    
    // Set the offset into the visibility result buffer.
    [_renderEncoder setVisibilityResultMode:MTLVisibilityResultModeCounting
                                     offset:AAPLGreenSphereIndex * sizeof(uint64_t)];
    
    // Encode the green sphere for drawing.
    [self renderMeshWithIndex:(uint32_t)AAPLGreenSphereIndex];
}

#pragma mark Mode 2: Occlusion culling

/// Configures the app's state to prepare encoding rendering commands for the second mode, which counts the number of sphere occlusions.
- (void)updateOcclusionCullingMode
{
    // Calculate the constants to organize the spheres in a grid.
    const simd_float3 gridCenter = simd_make_float3((float)(AAPLNumObjectsX - 1) / 2.0f,
                                                    (float)(AAPLNumObjectsY - 1) / 2.0f,
                                                    0.0f);
    const simd_float3 gridScale = simd_make_float3(2.0f, 2.0f, -2.0f);

    // Calculate the horizontal position offset and distance for the camera.
    // The horizontal position of the spheres is dependent on the `_position` variable.

    /// The distance of the camera to the grid, based on the number of objects in one row.
    const simd_float3 cameraCenter = simd_make_float3(_position, 0.0f, -3.0f - (float)AAPLNumObjectsX);
    
    AAPLFrameData* frameData = (_frameDataBuffer[_frameDataBufferIndex]).contents;
    size_t objectIndex = 0;
    for (int z = 0; z < AAPLNumObjectsZ; z++)
    {
        for (int y = 0; y < AAPLNumObjectsY; y++)
        {
            for (int x = 0; x < AAPLNumObjectsX; x++)
            {
                // Calculate the position of the object in the grid.
                simd_float3 position = cameraCenter + gridScale * (simd_make_float3(x, y, z) - gridCenter);
                matrix_float4x4 modelViewMatrix = matrix4x4_translation(position.x, position.y, position.z);
                frameData->objects[objectIndex].modelViewMatrix = modelViewMatrix;
                frameData->objects[objectIndex].modelViewProjMatrix = matrix_multiply(_projectionMatrix, modelViewMatrix);
                frameData->objects[objectIndex].color = simd_make_float3((x + 1.0f) / 5.0f, y / 4.0f, z / 16.0f);
                objectIndex++;
            }
        }
    }
}

/// Renders the main pass of the occlusion-culling mode.
///
/// It avoids rendering invisible geometry by checking the `_readFromVisibilityResultBuffer` array.
- (void)renderMainRenderPass
{
    size_t numDrawCalls = 0;
        
    [_renderEncoder pushDebugGroup:@"render"];
    
    // Encode the sphere's vertex data.
    [self setMeshBuffers:_sphereVertices indexBuffer:_sphereIndices indexCount:_sphereIndexCount];
    
    // Draw a visible sphere for every corresponding visible icosahedron.
    for (size_t i = 0; i < AAPLNumObjectsXYZ; ++i)
    {
        // If an icosahedron is visible, draw the sphere.
        if (_readFromVisibilityResultBuffer[i])
        {
            [self renderMeshWithIndex:(uint32_t)i];
            numDrawCalls++;
        }
    }
    
    [_renderEncoder popDebugGroup];
    
    // Set the result property so the view controller can update the label.
    self->_numSpheresDrawn = numDrawCalls;
}

/// Render icosahedrons into the result of the main render pass to determine which spheres are potentially visible.
///
/// The method disables depth writes because the render pass doesn't actually draw into the depth buffer.
- (void)renderProxyGeometry
{
    // Configure the pipeline state object and depth state to disable writing to the color and depth attachments.
    [_renderEncoder setRenderPipelineState:_pipelineStateNoRender];
    [_renderEncoder setDepthStencilState:_depthStateDisableWrites];
    
    [_renderEncoder pushDebugGroup:@"proxy geometry"];
    
    // Encode the icosahedron's vertices.
    [self setMeshBuffers:_icosahedronVertices indexBuffer:_icosahedronIndices indexCount:_icosahedronIndexCount];
    
    // Draw each icosahedron and check its visibility.
    for (size_t i = 0; i < AAPLNumObjectsXYZ; ++i)
    {
        [_renderEncoder setVisibilityResultMode:MTLVisibilityResultModeBoolean
                                         offset:i * sizeof(uint64_t)];
        [self renderMeshWithIndex:(uint32_t)i];
    }
    
    [_renderEncoder popDebugGroup];
}

/// Encodes a render pass that counts the number of spheres that other spheres obstruct with a visibility result buffer.
- (void)renderOcclusionCullingMode
{
    // Encode the main render pass. It culls geometry based on the `_readFromVisibilityResultBuffer` array.
    [self renderMainRenderPass];
    
    // Encode the occlusion query pass. Note that a separate render command encoder isn't necessary.
    [self renderProxyGeometry];
}

#pragma mark MTKView Drawing Code

/// Updates the app's state and draws each frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Prevent the app from rendering more than `AAPLMaxBuffersInFlight` frames at once.
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    
    // Update the state of the constant data buffers before rendering.
    _frameDataBufferIndex = (_frameDataBufferIndex + 1) % AAPLMaxBuffersInFlight;
    _visibilityBufferWriteIndex = (_visibilityBufferWriteIndex + 1) % AAPLNumVisibilityBuffers;

    // Read the visibility buffer result from the previous frame.
    _readFromVisibilityResultBuffer = _visibilityBuffer[_visibilityBufferReadIndex].contents;

    // Create a command buffer.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Metal Visibility Buffer Command";
    
    // Set up a render pass descriptor to clear the screen.
    // It doesn't need to store the depth buffer because it's the only one for each frame.
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.5f, 1.0f, 0.0f);
            
    // Add the visibility result buffer to this render pass.
    renderPassDescriptor.visibilityResultBuffer = _visibilityBuffer[_visibilityBufferWriteIndex];

    // Create a render encoder for drawing.
    _renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

    _renderEncoder.label = (_visibilityTestingMode == AAPLFragmentCountingMode) ? @"Fragment Counting" : @"Occlusion Culling";

    // Configure the encoder and its pipeline state.
    [_renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [_renderEncoder setCullMode:MTLCullModeBack];
    [_renderEncoder setRenderPipelineState:_pipelineState];
    [_renderEncoder setDepthStencilState:_depthState];
    
    // Encode the frame's constants buffer.
    [_renderEncoder setVertexBuffer:_frameDataBuffer[_frameDataBufferIndex]
                             offset:0
                            atIndex:AAPLBufferIndexFrameData];
    
    // Render the fragment-counting mode or the occlusion-culling mode.
    if (_visibilityTestingMode == AAPLFragmentCountingMode)
    {
        // Render the frame in fragment-counting mode.
        [self updateFragmentCountingMode];
        [self renderFragmentCountingMode];
    }
    else if (_visibilityTestingMode == AAPLOcclusionCullingMode)
    {
        // Render the frame in occlusion-culling mode.
        [self updateOcclusionCullingMode];
        [self renderOcclusionCullingMode];
    }
    
    // Stop encoding drawing commands.
    [_renderEncoder endEncoding];
    
    // Submit the command buffer to the GPU so it can begin rendering the frame.
    
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
        // Avoid a data race condition by updating the visibility buffer's read index when the command buffer finishes.
        self->_visibilityBufferReadIndex = (self->_visibilityBufferReadIndex + 1) % AAPLNumVisibilityBuffers;

        // Allow the app to start another frame by dispatching the in-flight semaphore.
        dispatch_semaphore_signal(block_sema);
    }];
    
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

/// Responds to drawable size or orientation changes.
- (void)drawableSizeWillChange:(CGSize)size
{
    float aspect = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

#pragma mark Matrix Math Utilities

/// Returns a scaling matrix.
matrix_float4x4 matrix4x4_scaling(float s) {
    return (matrix_float4x4) {{
        { s, 0, 0, 0 },
        { 0, s, 0, 0 },
        { 0, 0, s, 0 },
        { 0, 0, 0, 1 }
    }};
}

/// Returns a translation matrix.
matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
    }};
}

/// Returns a perspective transform matrix.
matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);
    
    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}

@end
