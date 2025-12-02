/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <simd/simd.h>
#import <MetalKit/MetalKit.h>

#import "AAPLRenderer.h"

// Include the headers that share types between the C code here, which executes
// Metal API commands, and the .metal files, which use the types as inputs to the shaders.
#import "AAPLShaderTypes-Common.h"

#ifdef USE_METAL3
#import "AAPLShaderTypes-Metal3.h"
#else
#import "AAPLShaderTypes-Metal2.h"
#endif

// The main class performing the rendering.
@implementation AAPLRenderer
{
    id <MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;

    // The Metal buffers for storing the vertex data.
    id<MTLBuffer> _vertexBuffer;

    // The number of vertices in the vertex buffer.
    NSUInteger _numVertices;

    // The render pipeline for drawing the quad.
    id<MTLRenderPipelineState> _pipelineState;

    // The Metal texture object to reference with an argument buffer.
    id<MTLTexture> _texture;

    // The Metal sampler object to reference with an argument buffer.
    id<MTLSamplerState> _sampler;

    // The Metal buffer object to reference with an argument buffer.
    id<MTLBuffer> _indirectBuffer;

    // The buffer that contains arguments for the fragment shader.
    id<MTLBuffer> _fragmentShaderArgumentBuffer;

    // The viewport to maintain 1:1 aspect ratio.
    MTLViewport _viewport;
}

/// Initialize with the MetalKit view that contains the Metal device.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;

        mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0f);

        // Create a vertex buffer, and initialize it with the generics array.
        {
            static const AAPLVertex vertexData[] =
            {
                //      Vertex      |  Texture    |         Vertex
                //     Positions    | Coordinates |         Colors
                { {  .75f,  -.75f }, { 1.f, 0.f }, { 0.f, 1.f, 0.f, 1.f } },
                { { -.75f,  -.75f }, { 0.f, 0.f }, { 1.f, 1.f, 1.f, 1.f } },
                { { -.75f,   .75f }, { 0.f, 1.f }, { 0.f, 0.f, 1.f, 1.f } },
                { {  .75f,  -.75f }, { 1.f, 0.f }, { 0.f, 1.f, 0.f, 1.f } },
                { { -.75f,   .75f }, { 0.f, 1.f }, { 0.f, 0.f, 1.f, 1.f } },
                { {  .75f,   .75f }, { 1.f, 1.f }, { 1.f, 1.f, 1.f, 1.f } },
            };

            _vertexBuffer = [_device newBufferWithBytes:vertexData
                                                 length:sizeof(vertexData)
                                                options:MTLResourceStorageModeShared];

            _vertexBuffer.label = @"Vertices";
        }

        // Create texture to apply to the quad.
        {
            NSError *error;

            MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

            _texture = [textureLoader newTextureWithName:@"Text"
                                             scaleFactor:1.0
                                                  bundle:nil
                                                 options:nil
                                                   error:&error];

            NSAssert(_texture, @"Could not load foregroundTexture: %@", error);

            _texture.label = @"Text";
        }

        // Create a sampler to use for texturing/
        {
            MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
            samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
            samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
            samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
            samplerDesc.normalizedCoordinates = YES;
            samplerDesc.supportArgumentBuffers = YES;

            _sampler = [_device newSamplerStateWithDescriptor:samplerDesc];
        }

        uint16_t bufferElements = 256;

        // Create buffers for making a pattern on the quad.
        {
            _indirectBuffer = [_device newBufferWithLength:sizeof(float) * bufferElements
                                                   options:MTLResourceStorageModeShared];

            float * const patternArray = (float *) _indirectBuffer.contents;

            for(uint16_t i = 0; i < bufferElements; i++) {
                patternArray[i] = ((i % 24) < 3) * 1.0;
            }

            _indirectBuffer.label = @"Indirect Buffer";
        }

    
        // Create the render pipeline state.
        {
            id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

            id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

            id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

            NSError *error;

            // Set up a descriptor for creating a pipeline state object.
            MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineStateDescriptor.label = @"Argument Buffer Example";
            pipelineStateDescriptor.vertexFunction = vertexFunction;
            pipelineStateDescriptor.fragmentFunction = fragmentFunction;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
            _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                     error:&error];

            NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        }


        // Create the argument buffer.
#ifdef USE_METAL3
        {
            NSAssert(_device.argumentBuffersSupport != MTLArgumentBuffersTier1,
                     @"Metal 3 argument buffers are suppported only on Tier2 devices");

            NSUInteger argumentBufferLength = sizeof(FragmentShaderArguments);

            _fragmentShaderArgumentBuffer = [_device newBufferWithLength:argumentBufferLength options:0];

            FragmentShaderArguments *argumentStructure = (FragmentShaderArguments *)_fragmentShaderArgumentBuffer.contents;

            argumentStructure->exampleTexture = _texture.gpuResourceID;
            argumentStructure->exampleBuffer = (float*) _indirectBuffer.gpuAddress;
            argumentStructure->exampleSampler = _sampler.gpuResourceID;
            argumentStructure->exampleConstant = bufferElements;
        }
#else
        {
            id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

            id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

            id <MTLArgumentEncoder> argumentEncoder =
                [fragmentFunction newArgumentEncoderWithBufferIndex:AAPLFragmentBufferIndexArguments];

            NSUInteger argumentBufferLength = argumentEncoder.encodedLength;

            _fragmentShaderArgumentBuffer = [_device newBufferWithLength:argumentBufferLength options:0];

            _fragmentShaderArgumentBuffer.label = @"Argument Buffer";
            
            [argumentEncoder setArgumentBuffer:_fragmentShaderArgumentBuffer offset:0];

            [argumentEncoder setTexture:_texture atIndex:AAPLArgumentBufferIDExampleTexture];
            [argumentEncoder setSamplerState:_sampler atIndex:AAPLArgumentBufferIDExampleSampler];
            [argumentEncoder setBuffer:_indirectBuffer offset:0 atIndex:AAPLArgumentBufferIDExampleBuffer];

            uint32_t *numElementsAddress =  (uint32_t *)[argumentEncoder constantDataAtIndex:AAPLArgumentBufferIDExampleConstant];

            *numElementsAddress = bufferElements;
        }
#endif

        // Create the command queue.
        _commandQueue = [_device newCommandQueue];
    }

    return self;
}

/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Create a new command buffer for each render pass to the current drawable.
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Obtain a renderPassDescriptor with the view's drawable texture.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder to render with.
        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder setViewport:_viewport];

        // Indicate to Metal that the GPU accesses these resources, so they need
        // to map to the GPU's address space.
        [renderEncoder useResource:_texture usage:MTLResourceUsageRead stages:MTLRenderStageFragment];
        [renderEncoder useResource:_indirectBuffer usage:MTLResourceUsageRead stages:MTLRenderStageFragment];

        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:AAPLVertexBufferIndexVertices];

        [renderEncoder setFragmentBuffer:_fragmentShaderArgumentBuffer
                                  offset:0
                                 atIndex:AAPLFragmentBufferIndexArguments];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];

        [renderEncoder endEncoding];

        // Schedule a present after the framebuffer is complete using the current drawable.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finalize rendering here and push the command buffer to the GPU.
    [commandBuffer commit];
}

/// Called whenever the view changes orientation or resizes.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Calculate a viewport so that it's always square and in the middle of the drawable.

    if(size.width < size.height) {
        _viewport.originX = 0;
        _viewport.originY = (size.height - size.width) / 2.0;;
        _viewport.width = _viewport.height = size.width;
        _viewport.zfar = 1.0;
        _viewport.znear = -1.0;
    } else {
        _viewport.originX = (size.width - size.height) / 2.0;
        _viewport.originY = 0;
        _viewport.width = _viewport.height = size.height;
        _viewport.zfar = 1.0;
        _viewport.znear = -1.0;
    }
}

@end

