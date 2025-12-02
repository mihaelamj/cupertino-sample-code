/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import "AAPLRenderer.h"
#import "AAPLShaderTypes.h"

//------------------------------------------------------------------------------
@implementation AAPLRenderer
{
    MTKView                    *_view;
    id<MTLDevice>              _device;
    id<MTLCommandQueue>        _commandQueue;

    id<MTLRenderPipelineState> _pipelineState;

    vector_uint2 _viewportSize;

    // A flag indicating that the app already drew the scene to
    // read the pixel data.
    BOOL _drewSceneForReadThisFrame;

    // Buffer to contain pixels blit from drawable.
    id<MTLBuffer> _readBuffer;
}

#pragma mark Initialization

- (instancetype)initWithMetalKitView:(nonnull MTKView*)view
{
    self = [super init];
    if (self)
    {
        _view   = view;
        _device = view.device;
        _commandQueue = [_device newCommandQueue];

        _view.framebufferOnly = NO;
        ((CAMetalLayer*)_view.layer).allowsNextDrawableTimeout = NO;
        _view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;


        _view.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);

        {
            id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

            MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineStateDescriptor.label = @"Pipeline";
            pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];;
            pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = _view.colorPixelFormat;

            NSError *error;
            _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                     error:&error];

            NSAssert(_pipelineState, @"Failed to create pipeline state, error: %@", error);
        }

    }

    return self;
}

//------------------------------------------------------------------------------
#pragma mark MTKView Delegate Methods

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView*)view
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Render the Scene";

    if (!_drewSceneForReadThisFrame)
    {
        [self drawScene:view withCommandBuffer:commandBuffer];
    }

    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];

    _drewSceneForReadThisFrame = NO;
}

//------------------------------------------------------------------------------
#pragma mark Drawing and Reading Methods

// Encode drawing commands to the given command buffer.
- (void)drawScene:(MTKView*)view withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"Render Encoder";

    // Encode the render pipeline state and viewport for the scene.
    [renderEncoder setRenderPipelineState:_pipelineState];

    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:AAPLVertexInputIndexViewport];

    // Encode the draw commands for the colored quad.
    {
        const AAPLVertex quadVertices[] =
        {
            //         Positions,                    Colors
            { {                0,               0 }, { 1, 0, 0, 1 } },
            { {  _viewportSize.x,               0 }, { 0, 1, 0, 1 } },
            { {  _viewportSize.x, _viewportSize.y }, { 0, 0, 1, 1 } },

            { {  _viewportSize.x, _viewportSize.y }, { 0, 0, 1, 1 } },
            { {                0, _viewportSize.y }, { 1, 1, 1, 1 } },
            { {                0,               0 }, { 1, 0, 0, 1 } },
        };

        [renderEncoder setVertexBytes:quadVertices
                               length:sizeof(quadVertices)
                              atIndex:AAPLVertexInputIndexVertices];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
    }

    // Set up the state and encode the draw command.
    if (_drawOutline)
    {
        const float x = _outlineRect.origin.x;
        const float y = _outlineRect.origin.y;
        const float w = _outlineRect.size.width;
        const float h = _outlineRect.size.height;
        const AAPLVertex outlineVertices[] =
        {
            // Positions,     Colors (all white)
            { {   x,   y },  { 1, 1, 1, 1 } }, // Lower-left corner.
            { {   x, y+h },  { 1, 1, 1, 1 } }, // Upper-left corner.
            { { x+w, y+h },  { 1, 1, 1, 1 } }, // Upper-right corner.
            { { x+w,   y },  { 1, 1, 1, 1 } }, // Lower-right corner.
            { {   x,   y },  { 1, 1, 1, 1 } }, // Lower-left corner (to complete the line strip).
        };

        [renderEncoder setVertexBytes:outlineVertices
                               length:sizeof(outlineVertices)
                              atIndex:AAPLVertexInputIndexVertices];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeLineStrip
                          vertexStart:0
                          vertexCount:5];
    }

    [renderEncoder endEncoding];
}

//------------------------------------------------------------------------------
// Set this to print the pixels obtained by reading the texture.
#define AAPL_PRINT_PIXELS_READ 0

- (nonnull AAPLImage*)renderAndReadPixelsFromView:(nonnull MTKView*)view withRegion:(CGRect)region
{

    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    // Encode a render pass to render the image to the drawable texture.
    [self drawScene:view withCommandBuffer:commandBuffer];
    

    _drewSceneForReadThisFrame = YES;

    id<MTLTexture> readTexture = view.currentDrawable.texture;

    MTLOrigin readOrigin = MTLOriginMake(region.origin.x, region.origin.y, 0);
    MTLSize readSize = MTLSizeMake(region.size.width, region.size.height, 1);
    
    const id<MTLBuffer> pixelBuffer = [self readPixelsWithCommandBuffer:commandBuffer
                                                            fromTexture:readTexture
                                                               atOrigin:readOrigin
                                                               withSize:readSize];



    AAPLPixelBGRA8Unorm *pixels = (AAPLPixelBGRA8Unorm *)pixelBuffer.contents;

#if AAPL_PRINT_PIXELS_READ
    // Process the pixel data.
    printf("Pixels read: wh[%d %d] at xy[%d %d].\n",
        (int)readSize.width, (int)readSize.height,
        (int)readOrigin.x,   (int)readOrigin.y);

    AAPLPixelBGRA8Unorm *row = pixels;

    for (int yy = 0;  yy < readSize.height;  yy++)
    {
        for (int xx = 0;  xx < MIN(5, readSize.width);  xx++)
        {
            unsigned int pixel = *(unsigned int *)&row[xx];
            printf("[%4d=x, %4d=y] x%8X\n", (int)readOrigin.x + xx, (int)readOrigin.y + yy, pixel);
        }
        printf("\n");
        row += readSize.width;  // Advance to the next row.
    }
#endif

    // Create an `NSData` object and initialize it with the pixel data.
    // Use the CPU to copy the pixel data from the `pixelBuffer.contents`
    // pointer to `data`.
    NSData *data = [[NSData alloc] initWithBytes:pixels length:pixelBuffer.length];

    // Create a new image from the pixel data.
    AAPLImage *image = [[AAPLImage alloc] initWithBGRA8UnormData:data
                                                           width:readSize.width
                                                          height:readSize.height];

    return image;
}

//------------------------------------------------------------------------------

// The sample only supports the `MTLPixelFormatBGRA8Unorm` and
// `MTLPixelFormatR32Uint` formats.
static inline uint32_t sizeofPixelFormat(NSUInteger format)
{
    return ((format) == MTLPixelFormatBGRA8Unorm ? 4 :
            (format) == MTLPixelFormatR32Uint    ? 4 : 0);
}

- (id<MTLBuffer>)readPixelsWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                 fromTexture:(id<MTLTexture>)texture
                                    atOrigin:(MTLOrigin)origin
                                    withSize:(MTLSize)size
{
    MTLPixelFormat pixelFormat = texture.pixelFormat;
    switch (pixelFormat)
    {
        case MTLPixelFormatBGRA8Unorm:
        case MTLPixelFormatR32Uint:
            break;
        default:
            NSAssert(0, @"Unsupported pixel format: 0x%X.", (uint32_t)pixelFormat);
    }

    // Check for attempts to read pixels outside the texture.
    // In this sample, the calling code validates the region, so just assert.
    NSAssert(origin.x >= 0, @"Reading outside the left texture bounds.");
    NSAssert(origin.y >= 0, @"Reading outside the top texture bounds.");
    NSAssert((origin.x + size.width)  < texture.width,  @"Reading outside the right texture bounds.");
    NSAssert((origin.y + size.height) < texture.height, @"Reading outside the bottom texture bounds.");

    NSAssert(!((size.width == 0) || (size.height == 0)), @"Reading zero-sized area: %dx%d.", (uint32_t)size.width, (uint32_t)size.height);

    NSUInteger bytesPerPixel = sizeofPixelFormat(texture.pixelFormat);
    NSUInteger bytesPerRow   = size.width * bytesPerPixel;
    NSUInteger bytesPerImage = size.height * bytesPerRow;

    _readBuffer = [texture.device newBufferWithLength:bytesPerImage options:MTLResourceStorageModeShared];

    NSAssert(_readBuffer, @"Failed to create buffer for %zu bytes.", bytesPerImage);

    // Copy the pixel data of the selected region to a Metal buffer with a shared
    // storage mode, which makes the buffer accessible to the CPU.
    id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];

    [blitEncoder copyFromTexture:texture
                     sourceSlice:0
                     sourceLevel:0
                    sourceOrigin:origin
                      sourceSize:size
                        toBuffer:_readBuffer
               destinationOffset:0
          destinationBytesPerRow:bytesPerRow
        destinationBytesPerImage:bytesPerImage];

    [blitEncoder endEncoding];

    [commandBuffer commit];
    
    // The app must wait for the GPU to complete the blit pass before it can
    // read data from _readBuffer.
    [commandBuffer waitUntilCompleted];

    // Calling waitUntilCompleted blocks the CPU thread until the blit operation
    // completes on the GPU. This is generally undesirable as apps should maximize
    // parallelization between CPU and GPU execution. Instead of blocking here, you
    // could process the pixels in a completion handler using:
    //      [commandBuffer addCompletedHandler:...];



    return _readBuffer;
}

@end    // @implementation AAPLRenderer

