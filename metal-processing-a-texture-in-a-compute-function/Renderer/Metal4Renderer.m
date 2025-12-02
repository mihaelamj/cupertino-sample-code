/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform-independent Metal renderer implementation that sets up the app's
 resources once and then draws each frame.
*/

@import simd;
@import MetalKit;

#import <Metal/MTL4RenderPass.h>

#import "Metal4Renderer.h"
#import "TGAImage.h"


// The shader types header that defines the input data types for the app's shaders.
// The types define a common data format for both
// the `.metal` shader source code files, which run on the GPU,
// and the code in this file, which sets up input data with Metal API on the CPU.
#import "ShaderTypes.h"

/// An array of tuples that store the position and texture coordinates for each vertex.
///
/// The array stores the data for four triangles.
/// The initial two triangles make a rectangle for the composite color texture.
/// The final two triangles make a rectangle for the composite grayscale texture.
///
static const VertexData triangleVertexData[] =
{
    // The 1st triangle of the rectangle for the composite color texture.
    { {  480,   40 },  { 1.f, 1.f } },
    { { -480,   40 },  { 0.f, 1.f } },
    { { -480,  720 },  { 0.f, 0.f } },

    // The 2nd triangle of the rectangle for the composite color texture.
    { {  480,   40 },  { 1.f, 1.f } },
    { { -480,  720 },  { 0.f, 0.f } },
    { {  480,  720 },  { 1.f, 0.f } },

    // The 1st triangle of the rectangle for the composite grayscale texture.
    { {  480, -720 },  { 1.f, 1.f } },
    { { -480, -720 },  { 0.f, 1.f } },
    { { -480,  -40 },  { 0.f, 0.f } },

    // The 2nd triangle of the rectangle for the composite grayscale texture.
    { {  480, -720 },  { 1.f, 1.f } },
    { { -480,  -40 },  { 0.f, 0.f } },
    { {  480,  -40 },  { 1.f, 0.f } },
};

static const MTLOrigin zeroOrigin = { 0, 0, 0 };

#define kMaxFramesInFlight 3

/// A class that renders each of the app's video frames.
@implementation Metal4Renderer
{
    /// A Metal device the renderer draws with by sending commands to it.
    id<MTLDevice> device;
    
    /// A Metal compiler that compiles the app's shaders into pipelines.
    id<MTL4Compiler> compiler;

    /// A default library that stores the app's shaders and compute kernels.
    ///
    /// Xcode compiles the shaders from the project's `.metal` files at build time
    /// and stores them in the default library inside the app's main bundle.
    id<MTLLibrary> defaultLibrary;

    /// A compute pipeline the app creates at runtime.
    ///
    /// The app compiles the pipeline with the compute kernel in the
    /// `AAPLShaders.metal` source code file.
    id<MTLComputePipelineState> computePipelineState;

    /// A render pipeline the app creates at runtime.
    ///
    /// The app compiles the pipeline with the vertex and fragment shaders in the
    /// `AAPLShaders.metal` source code file.
    id<MTLRenderPipelineState> renderPipelineState;

    /// A command queue the app uses to send command buffers to the Metal device.
    id<MTL4CommandQueue> commandQueue;

    /// An array of allocators, each of which manages memory for a command buffer.
    ///
    /// Each allocator provides backing memory for the commands the app encodes
    /// into a command buffer..
    id<MTL4CommandAllocator> commandAllocators[kMaxFramesInFlight];

    /// A reusable command buffer the render encodes draw commands to for each frame.
    id<MTL4CommandBuffer> commandBuffer;

    /// An argument table that stores the resource bindings for both
    /// render and compute encoders.
    id<MTL4ArgumentTable> argumentTable;

    /// A residency set that keeps resources in memory for the app's lifetime.
    id<MTLResidencySet> residencySet;

    /// A shared event that the GPU signals to indicate to the CPU that it's
    /// finished work.
    id<MTLSharedEvent> sharedEvent;

    /// An integer that tracks the current frame number.
    uint64_t frameNumber;
    
    /// A texture that stores the original background image.
    ///
    /// The app build a color image by combines this texture with
    /// `chyronTexture`, which becomes the input texture for the grayscale conversion.
    id<MTLTexture> backgroundImageTexture;

    /// A texture that stores the original chyron image.
    ///
    /// The app build a color image by combines this texture with
    /// `backgroundImageTexture`, which becomes the input texture for the grayscale conversion.
    id<MTLTexture> chyronTexture;

    /// A texture that stores the a color copy of the background image and the chyron image.
    ///
    /// This is the input  texture for the compute pass that runs the `convertToGrayscale` kernel.
    id<MTLTexture> compositeColorTexture;

    /// A texture that stores the a color copy of the background image and the chyron image.
    ///
    /// This is the output  texture for the compute pass that runs the `convertToGrayscale` kernel.
    id<MTLTexture> compositeGrayscaleTexture;

    /// A two-dimensional size that represents the number of threads for each
    /// grid dimension of a threadgroup for a compute kernel dispatch.
    MTLSize threadgroupSize;

    /// A two-dimensional size that represents the number of threads in a
    /// threadgroup for a compute kernel dispatch.
    MTLSize threadgroupCount;

    /// A buffer that stores the triangle vertex data for the render pass.
    ///
    /// The app stores a copy of the data from `triangleVertexData`.
    id<MTLBuffer> vertexDataBuffer;

    /// The current size of the view, which the app sends as an input to the
    /// vertex shader.
    simd_uint2 viewportSize;

    /// A buffer that stores the viewport's size data.
    ///
    /// This acts as a GPU-visible container for the value in ``viewportSize``.
    id<MTLBuffer> viewportSizeBuffer;
}

/// Creates a texture instance from an image file.
///
/// The method configures the texture with a pixel format with 4 color channels:
/// - blue
/// - green
/// - red
/// - alpha
///
/// Each channel is an 8-bit unnormalized value.
///
/// For example:
/// - `0` maps to `0.0`,
/// - `255` maps to `1.0`.
///
/// - Returns: A texture instance if the method succeeds; otherwise `nil`.
- (id<MTLTexture>)loadImageToTexture:(NSURL *)imageFileLocation
{
    // Load an image from a URL.
    TGAImage *image;
    image = [[TGAImage alloc] initWithTGAFileAtLocation:imageFileLocation];

    if (!image)
    {
        return nil;
    }

    // Create and configure the texture descriptor to make a texture that's the
    // same size as the image.
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];

    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;

    // Create the texture instance.
    id<MTLTexture> texture;
    texture = [device newTextureWithDescriptor:textureDescriptor];

    if (nil == texture)
    {
        NSLog(@"The device can't create a texture for the image at: %@",
              imageFileLocation);
        return nil;
    }

    // Define a region that's the size of the texture, which is the same as the image.
    const MTLSize size = {
        textureDescriptor.width,
        textureDescriptor.height,
        1
    };
    const MTLRegion region = { zeroOrigin, size };

    /// The number of bytes in each of the texture's rows.
    NSUInteger bytesPerRow = 4 * textureDescriptor.width;

    // Copy the bytes from the image into the texture.
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:image.data.bytes
               bytesPerRow:bytesPerRow];

    return texture;
}

/// Creates a compiler to create pipelines from shaders.
- (void) createCompiler
{
    MTL4CompilerDescriptor *compilerDescriptor;
    compilerDescriptor = [[MTL4CompilerDescriptor alloc] init];
    
    // Create a compiler with the descriptor.
    NSError *error = NULL;
    compiler = [device newCompilerWithDescriptor:compilerDescriptor
                                            error:&error];
    
    // Verify the device created the compiler successfully.
    NSAssert(nil != compiler,
             @"The device can't create a compiler due to: %@",
             error);
}

/// Creates a compute pipeline with a kernel function.
- (void) createComputePipeline
{
    NSError *error = NULL;

    // Get the kernel function from the default library.
    MTL4LibraryFunctionDescriptor *kernelFunction;
    kernelFunction = [MTL4LibraryFunctionDescriptor new];
    kernelFunction.library = defaultLibrary;
    kernelFunction.name = @"convertToGrayscale";
    
    // Configure a compute pipeline with the compute function.
    MTL4ComputePipelineDescriptor *pipelineDescriptor;
    pipelineDescriptor = [MTL4ComputePipelineDescriptor new];
    pipelineDescriptor.computeFunctionDescriptor = kernelFunction;

    // Create a compute pipeline with the image processing kernel in the library.
    computePipelineState = [compiler newComputePipelineStateWithDescriptor:pipelineDescriptor
                                                       compilerTaskOptions:nil
                                                                     error:&error];
    
    // Verify the compiler created the pipeline state successfully.
    // Debug builds in Xcode turn on Metal API Validation by default.
    NSAssert(nil != computePipelineState,
             @"The compiler can't create a compute pipeline with kernel function: %@",
             kernelFunction.name);
}

- (void) createRenderPipelineFor:(MTLPixelFormat)pixelFormat
{
    NSError *error = NULL;

    // Get the vertex function from the default library.
    MTL4LibraryFunctionDescriptor *vertexFunction;
    vertexFunction = [MTL4LibraryFunctionDescriptor new];
    vertexFunction.library = defaultLibrary;
    vertexFunction.name = @"vertexShader";

    // Get the fragment function from the default library.
    MTL4LibraryFunctionDescriptor *fragmentFunction;
    fragmentFunction = [MTL4LibraryFunctionDescriptor new];
    fragmentFunction.library = defaultLibrary;
    fragmentFunction.name = @"samplingShader";

    // Configure a render pipeline with the vertex and fragment shaders.
    MTL4RenderPipelineDescriptor *pipelineDescriptor;
    pipelineDescriptor = [MTL4RenderPipelineDescriptor new];
    pipelineDescriptor.label = @"Simple Render Pipeline";
    pipelineDescriptor.vertexFunctionDescriptor = vertexFunction;
    pipelineDescriptor.fragmentFunctionDescriptor = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;

    renderPipelineState = [compiler newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                     compilerTaskOptions:nil
                                                                   error:&error];

    NSAssert(nil != renderPipelineState,
             @"The compiler can't create a render pipeline due to: %@",
             error);
}

- (void) createBuffers
{
    // Create the buffer that stores the vertex data.
    vertexDataBuffer = [device newBufferWithLength:sizeof(triangleVertexData)
                                             options:MTLResourceStorageModeShared];

    memcpy(vertexDataBuffer.contents, triangleVertexData, sizeof(triangleVertexData));

    // Create the buffer that stores the app's viewport data.
    viewportSizeBuffer = [device newBufferWithLength:sizeof(viewportSize)
                                             options:MTLResourceStorageModeShared];

    [self updateViewportSizeBuffer];
}

/// Loads two textures the app combines into the source color texture.
- (void) createTextures
{
    NSString *chyronImageFileName = @"Aloha-chyron";
    NSString *backgroundImageFileName = @"Hawaii-coastline";
    // Create a texture from the background image file.
    NSURL *backgroundImageFile = [[NSBundle mainBundle]
                                URLForResource:backgroundImageFileName
                                withExtension:@"tga"];
    backgroundImageTexture = [self loadImageToTexture:backgroundImageFile];
    NSAssert(nil != backgroundImageTexture,
             @"The app can't create a texture for the background image: %@",
             backgroundImageFileName);

    // Create a texture from the chyron image file.
    NSURL *chyronImageFile = [[NSBundle mainBundle]
                              URLForResource:chyronImageFileName
                              withExtension:@"tga"];
    chyronTexture = [self loadImageToTexture:chyronImageFile];

    NSAssert(nil != chyronTexture,
             @"The app can't create a texture for the chyron image: %@",
             chyronImageFileName);

    // Create the source color texture that stores the combined texture data.
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;

    // Configure the pixel format with 4 channels: blue, green, red, and alpha.
    // Each is an 8-bit, unnormalized value; `0` maps to `0.0` and `255` maps to `1.0`.
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = backgroundImageTexture.width;
    textureDescriptor.height = backgroundImageTexture.height + chyronTexture.height;

    // Configure the input texture to read-only because `convertToGrayscale` kernel
    // doesn't modify it.
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    compositeColorTexture = [device newTextureWithDescriptor:textureDescriptor];

    NSAssert(nil != compositeColorTexture,
             @"The device can't create a texture for the composite color image.");

    // Configure the output texture to read and write because the
    // `convertToGrayscale` kernel needs to sample and modify it.
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead ;
    compositeGrayscaleTexture = [device newTextureWithDescriptor:textureDescriptor];

    NSAssert(nil != compositeGrayscaleTexture,
             @"The device can't create a texture for the composite grayscale image.");
}

/// Configures the number of rows and columns in the threadgroups based on the input image's size.
///
/// The method ensures the grid covers an area that's at least as big as the
/// entire image.
- (void) configureThreadgroupForComputePasses
{
    NSAssert(compositeColorTexture, @"Create the composite color texture before configuring the threadgroup");

    // Set the compute kernel's threadgroup size to 16 x 16.
    threadgroupSize = MTLSizeMake(16, 16, 1);

    // Find the number of threadgroup widths the app needs to span the texture's full width.
    threadgroupCount.width  = compositeColorTexture.width  + threadgroupSize.width -  1;
    threadgroupCount.width /= threadgroupSize.width;

    // Find the number of threadgroup heights the app needs to span the texture's full width.
    threadgroupCount.height = compositeColorTexture.height + threadgroupSize.height - 1;
    threadgroupCount.height /= threadgroupSize.height;

    // Set depth to one because the image data is two-dimensional.
    threadgroupCount.depth = 1;
}

- (void) createArgumentTable
{
    // Create an argument table that stores 2 buffers and 2 textures.
    MTL4ArgumentTableDescriptor *argumentTableDescriptor;
    argumentTableDescriptor = [[MTL4ArgumentTableDescriptor alloc] init];

    // Configure the descriptor to store 2 buffers:
    // - A vertex buffer
    // - A viewport size buffer.
    argumentTableDescriptor.maxTextureBindCount = 2;
    argumentTableDescriptor.maxBufferBindCount = 2;

    // Create an argument table with the descriptor.
    NSError *error = NULL;
    argumentTable = [device newArgumentTableWithDescriptor:argumentTableDescriptor
                                                     error:&error];
    NSAssert(nil != argumentTable,
             @"The device can't create an argument table due to: %@", error);
}

- (void)createSharedEvent
{
    // Initialize the shared event to permit the renderer to start on the first frame.
    sharedEvent = [device newSharedEvent];
    sharedEvent.signaledValue = frameNumber;
}


- (void) createResidencySets
{
    NSError *error = NULL;

    // Create a communal residency set for resources the app needs for every frame.
    MTLResidencySetDescriptor *residencySetDescriptor;
    residencySetDescriptor = [MTLResidencySetDescriptor new];
    residencySet = [device newResidencySetWithDescriptor:residencySetDescriptor
                                                     error:&error];

    NSAssert(nil != residencySet,
             @"The device can't create a residency set due to: %@", error);

    // Add the communal residency set to the command queue.
    [commandQueue addResidencySet:residencySet];

    // Add the communal resources to the residency set.
    [residencySet addAllocation:backgroundImageTexture];
    [residencySet addAllocation:chyronTexture];
    [residencySet addAllocation:compositeColorTexture];
    [residencySet addAllocation:compositeGrayscaleTexture];
    [residencySet addAllocation:vertexDataBuffer];
    [residencySet addAllocation:viewportSizeBuffer];
    [residencySet commit];
    
    // Create per-frame allocators and residency sets.
    for (uint32_t i = 0; i < kMaxFramesInFlight; i++)
    {
        commandAllocators[i] = [device newCommandAllocator];
        NSAssert(nil != commandAllocators[i],
                 @"The device can't create an allocator set due to: %@", error);
    }
}

- (nonnull instancetype)initWithView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if (nil == self) { return nil; }

    frameNumber = 0;
    viewportSize.x = (simd_uint1)mtkView.drawableSize.width;
    viewportSize.y = (simd_uint1)mtkView.drawableSize.height;

    device = mtkView.device;
    
    commandQueue = [device newMTL4CommandQueue];
    commandBuffer = [device newCommandBuffer];
    defaultLibrary = [device newDefaultLibrary];

    // Create the app's resources.
    [self createBuffers];
    [self createTextures];

    // Create the types that manage the resources.
    [self createArgumentTable];
    [self createSharedEvent];
    [self createResidencySets];
    
    // Add the Metal layer's residency set to the queue.
    [commandQueue addResidencySet:((CAMetalLayer *)mtkView.layer).residencySet];

    // Create the compute pipeline.
    [self createCompiler];
    [self createComputePipeline];
    [self configureThreadgroupForComputePasses];

    // Configure the view's color format.
    const MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    mtkView.colorPixelFormat = pixelFormat;

    // Create the render pipeline.
    [self createRenderPipelineFor:pixelFormat];
    return self;
}

- (void) updateViewportSizeBuffer {
    memcpy(viewportSizeBuffer.contents, &viewportSize, sizeof(viewportSize));
}

/// The system calls this method whenever the view changes orientation or size.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Update the viewport property to its new size,
    // which the renderer passes to the vertex shader.
    viewportSize.x = (simd_uint1)size.width;
    viewportSize.y = (simd_uint1)size.height;

    [self updateViewportSizeBuffer];
}

- (void)encodeChyronTextureCopy:(id<MTL4ComputeCommandEncoder>)computeEncoder
{
    // Configure the copy command to use the entire chyron texture.
    MTLSize chyronTextureSize;
    chyronTextureSize.width = chyronTexture.width;
    chyronTextureSize.height = chyronTexture.height;
    chyronTextureSize.depth = 1;

    static NSUInteger offset = 0;
    static bool rightWard = true;

    // Set the chyron destination to the top of the color texture.
    MTLOrigin destinationOrigin = zeroOrigin;
    destinationOrigin.x = offset;

    const NSUInteger emptySpace = compositeColorTexture.width - chyronTexture.width;
    offset += rightWard ? 1 : -1;

    if (offset == 0 || offset == emptySpace)
        rightWard = !rightWard;

    // Encode a command that copies the chyron texture onto the color texture.
    [computeEncoder copyFromTexture:chyronTexture
                        sourceSlice:0
                        sourceLevel:0
                       sourceOrigin:zeroOrigin
                         sourceSize:chyronTextureSize
                          toTexture:compositeColorTexture
                   destinationSlice:0
                   destinationLevel:0
                  destinationOrigin:destinationOrigin];
}

- (void)encodeBackgroundTextureCopy:(id<MTL4ComputeCommandEncoder>)computeEncoder
{
    // Configure the next copy command to use the entire background texture.
    MTLSize backgroundImageSize;
    backgroundImageSize.width = backgroundImageTexture.width;
    backgroundImageSize.height = backgroundImageTexture.height;
    backgroundImageSize.depth = 1;

    // Copy the background image below the chyron.
    MTLOrigin destinationOrigin = zeroOrigin;
    destinationOrigin.y = chyronTexture.height;

    // Encode a command that copies the background texture onto the color texture.
    [computeEncoder copyFromTexture:backgroundImageTexture
                        sourceSlice:0
                        sourceLevel:0
                       sourceOrigin:zeroOrigin
                         sourceSize:backgroundImageSize
                          toTexture:compositeColorTexture
                   destinationSlice:0
                   destinationLevel:0
                  destinationOrigin:destinationOrigin];
}

- (void)encodeGrayscaleDispatchCommand:(id<MTL4ComputeCommandEncoder>)computeEncoder
{
    // Configure the encoder's pipeline state for the dispatch call.
    [computeEncoder setComputePipelineState:computePipelineState];

    // Configure the encoder's argument table for the dispatch call.
    [computeEncoder setArgumentTable:argumentTable];

    // Bind the composite color (input) texture in the argument table.
    [argumentTable setTexture:compositeColorTexture.gpuResourceID
                      atIndex:ComputeTextureBindingIndexForColorImage];

    // Bind the composite grayscale (output) texture in the argument table.
    [argumentTable setTexture:compositeGrayscaleTexture.gpuResourceID
                      atIndex:ComputeTextureBindingIndexForGrayscaleImage];

    // Run the dispatch with the pipeline state and current state of the argument table.
    [computeEncoder dispatchThreadgroups:threadgroupCount
                   threadsPerThreadgroup:threadgroupSize];

}

/// Adds two copy commands and a dispatch command to the compute pass.
///
/// - Parameter computeEncoder: A compute encoder, which creates a single compute pass.
///
/// The method first encodes two copy commands that combines two color textures
/// into a single color composite texture.
/// The GPU runs these commands at the same time because they write to different regions
/// of the destination texture with no overlap.
///
/// > Note: The GPU runs copy commands sequentially when they write to overlapping regions
/// of a destination.
///
/// The method then encodes a dispatch command that creates an grayscale equivalent
/// of the composite color texture with a compute kernel.
/// To prevent the GPU from starting the dispatch stage before the copy commands complete,
/// the method encodes an intrapass barrier that enforces that ordering.
- (void)encodeComputePassWithEncoder:(id<MTL4ComputeCommandEncoder>)computeEncoder
{
    // Copy the chyron texture to the color composite texture.
    [self encodeChyronTextureCopy:computeEncoder];

    // Copy the background image texture to the color composite texture.
    [self encodeBackgroundTextureCopy:computeEncoder];

    // Add a barrier that pauses the dispatch stage of the compute pass
    // from starting until the copy commands finish during their blit stage.
    [computeEncoder barrierAfterEncoderStages:MTLStageBlit
                          beforeEncoderStages:MTLStageDispatch
                            visibilityOptions:MTL4VisibilityOptionDevice];

    // Create a texture that's the grayscale equivalent of the color composite texture.
    [self encodeGrayscaleDispatchCommand:computeEncoder];
}

- (void)encodeRenderPassWithEncoder:(id<MTL4RenderCommandEncoder>)renderEncoder
{
    // Add a barrier that tells the GPU to wait for any previous dispatch kernels
    // to finish before running any subsequent vertex stages.
    [renderEncoder barrierAfterQueueStages:MTLStageDispatch
                              beforeStages:MTLStageVertex
                         visibilityOptions:MTL4VisibilityOptionDevice];

    // Configure the view-port with the size of the drawable region.
    MTLViewport viewPort;
    viewPort.originX = 0.0;
    viewPort.originY = 0.0;
    viewPort.width = (double)viewportSize.x;
    viewPort.height = (double)viewportSize.y;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;

    [renderEncoder setViewport:viewPort];

    // Configure the encoder with the renderer's main pipeline state.
    [renderEncoder setRenderPipelineState:renderPipelineState];

    // Set the encoder's argument table.
    [renderEncoder setArgumentTable:argumentTable
                           atStages:MTLRenderStageVertex | MTLRenderStageFragment];

    // Bind the buffer with the triangle data to the argument table.
    [argumentTable setAddress:vertexDataBuffer.gpuAddress
                      atIndex:BufferBindingIndexForVertexData];

    // Bind the buffer with the viewport's size to the argument table.
    [argumentTable setAddress:viewportSizeBuffer.gpuAddress
                      atIndex:BufferBindingIndexForViewportSize];

    // Bind the color composite texture.
    [argumentTable setTexture:compositeColorTexture.gpuResourceID
                      atIndex:RenderTextureBindingIndex];

    // Draw the first rectangle with the color composite texture.
    const NSUInteger firstRectangleOffset = 0;
    const NSUInteger rectangleVertexCount = 6;
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:firstRectangleOffset
                      vertexCount:rectangleVertexCount];

    // Bind the grayscale composite texture.
    [argumentTable setTexture:compositeGrayscaleTexture.gpuResourceID
                      atIndex:RenderTextureBindingIndex];

    // Draw the first rectangle with the grayscale composite texture.
    const NSUInteger secondRectangleOffset = 6;
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:secondRectangleOffset
                      vertexCount:rectangleVertexCount];
}

/// Draws a frame of content to a view's drawable.
/// - Parameter view: A view with a drawable that the renderer draws into.
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Retrieve the view's drawable.
    id<CAMetalDrawable> drawable = view.currentDrawable;

    if (nil == drawable)
    {
        NSLog(@"The view doesn't have an available drawable at this time.");
        return;
    }

    // Get the render pass descriptor from the view's drawable instance.
    MTL4RenderPassDescriptor *renderPassDescriptor = view.currentMTL4RenderPassDescriptor;

    if (nil == renderPassDescriptor)
    {
        NSLog(@"The view doesn't have a render pass descriptor for Metal 4.");
        return;
    }

    // Increment the frame number for this frame.
    frameNumber += 1;

    // Make a string with the current frame number,
    NSString *forFrameString = [NSString stringWithFormat:@" for frame: %llu", frameNumber];

    if (frameNumber >= kMaxFramesInFlight) {
        // Wait for the GPU to finish rendering the frame that's
        // `kMaxFramesInFlight` before this one, and then proceed to the next step.
        uint64_t previousValueToWaitFor = frameNumber - kMaxFramesInFlight;
        [sharedEvent waitUntilSignaledValue:previousValueToWaitFor
                                  timeoutMS:10];
    }

    /// The array index for this frame's resources.
    uint32_t frameIndex = frameNumber % kMaxFramesInFlight;

    /// An allocator that's next in the rotation for this frame.
    id<MTL4CommandAllocator> frameAllocator = commandAllocators[frameIndex];

    // Prepare to use or reuse the allocator by resetting it.
    [frameAllocator reset];

    // Reset the command buffer for the new frame.
    [commandBuffer beginCommandBufferWithAllocator:frameAllocator];

    // Assign the command buffer a unique label for this frame.
    commandBuffer.label = [@"Command buffer" stringByAppendingString:forFrameString];

    // === Compute pass ===
    // Create a compute encoder from the command buffer.
    id<MTL4ComputeCommandEncoder> computeEncoder;
    computeEncoder = [commandBuffer computeCommandEncoder];

    // Assign the compute encoder a unique label for this frame.
    computeEncoder.label = [@"Compute encoder" stringByAppendingString:forFrameString];

    // Encode a compute pass that copies the color textures and creates the grayscale texture.
    [self encodeComputePassWithEncoder:computeEncoder];

    // Mark the end of the compute pass.
    [computeEncoder endEncoding];

    // === Render pass ===
    // Create a render encoder from the command buffer.
    id<MTL4RenderCommandEncoder> renderEncoder =
    [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

    // Assign the render encoder a unique label for this frame.
    renderEncoder.label = [@"Render encoder" stringByAppendingString:forFrameString];

    // Encode a render pass that draws a rectangle each of the composite textures.
    [self encodeRenderPassWithEncoder:renderEncoder];

    // Mark the end of the render pass.
    [renderEncoder endEncoding];

    // Finalize the command buffer.
    [commandBuffer endCommandBuffer];

    // === Submit passes to the GPU ===
    // Wait until the drawable is ready for rendering.
    [commandQueue waitForDrawable:drawable];

    // Submit the command buffer to the GPU.
    [commandQueue commit:&commandBuffer count:1];

    // Notify the drawable when the GPU finishes running the passes in the command buffer.
    [commandQueue signalDrawable:drawable];

    // Show the final result of this frame on the display.
    [drawable present];

    // Signal when the GPU finishes rendering this frame with a shared event.
    [commandQueue signalEvent:sharedEvent value:frameNumber];
}

@end
