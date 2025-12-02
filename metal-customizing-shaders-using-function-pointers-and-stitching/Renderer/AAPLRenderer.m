/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

@import simd;
@import MetalKit;

#import "AAPLRenderer.h"

// Include header shared between C code here, which executes Metal API commands,
// and .metal files.
#import "AAPLShaderTypes.h"

typedef enum AAPLLibraryIndex
{
    AAPLLibraryIndexMandelbrot = 0,
    AAPLLibraryIndexCount = 1,
} AAPLLibraryIndex;

/// Main class that renders the view.
@implementation AAPLRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLRenderPipelineState> _renderPipeline;
    
    // Table of stitched visible functions.
    id<MTLVisibleFunctionTable> _visibleFunctionTable;
    
    // Current size of the view, an input to the vertex shader.
    vector_uint2 _viewportSize;
    
    // State control.
    BOOL useUserDylib;
    BOOL useSubtraction;
    int iterations;
}

/// Initialize with the MetalKit view's Metal device.  This MetalKit view also sets the pixelFormat
/// and other properties of the drawable.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        // Set initial UI state.
        useUserDylib = NO;
        useSubtraction = NO;
        iterations = 16;
        
        _device = mtkView.device;
        [self loadMetal:mtkView];
    }
    
    return self;
}

/// Update the render state with the current UI state.
- (void)updateRenderStateFor:(nonnull MTKView *)mtkView
           withVisualization:(BOOL)isDebugVisualization
        subtractionOperation:(BOOL)useSubtraction
                  iterations:(int)iterations
{
    self->useUserDylib = isDebugVisualization;
    self->useSubtraction = useSubtraction;
    self->iterations = iterations;
    [self loadMetal:mtkView];
}

/// Creates Metal render state objects, including shaders and pipeline state objects.
- (void)loadMetal:(nonnull MTKView*)mtkView
{
    NSArray<id<MTLLibrary>> *libraries = [self loadMetallibs];
    [self createRenderStateWithFunctionsAndLibraries:libraries];
    
    _commandQueue = [_device newCommandQueue];
}

/// Load the Metal library created with the "Build Executable Metal Library" build phase.
/// This library includes the functions in AAPLShaders.metal and the UserDylib.metallib
/// created in the "Build Dynamic Metal Library" build phase.
- (NSMutableArray<id<MTLLibrary>>*)loadMetallibs
{
    NSMutableArray<id<MTLLibrary>> *libraries = [[NSMutableArray alloc] initWithCapacity:AAPLLibraryIndexCount];
    NSError *error;
    libraries[AAPLLibraryIndexMandelbrot] = [_device newLibraryWithURL:[[NSBundle mainBundle]
                                                                        URLForResource:@"AAPLShaders"
                                                                        withExtension:@"metallib"]
                                                                 error:&error];
    NSAssert(libraries[AAPLLibraryIndexMandelbrot], @"Failed to load AAPLShaders metal library: %@", error);
    
    return libraries;
}

/// Creates a stitched function that adds or subtracts a vector c to the result of matrix A multiplied by vector z.
///
/// (A * z) +/- c
///
/// where:
///
///  A is float2x2(z.x, z.y, -z.y, z.x)
///  z is float2
///  c is float2
///
- (id<MTLFunction>)createStitchedFunction:(id<MTLLibrary>)metalLib subtract:(BOOL)subtract
{
    // Create the input nodes.
    // The output type of each input node is the type of that parameter in its
    // function signature.
    // For example, z and c output float2, which is the type of their function
    // parameters in [[visible]] float2 calculate_Z(float2 z, float2 c);
    MTLFunctionStitchingInputNode *zInput = [[MTLFunctionStitchingInputNode alloc] initWithArgumentIndex:0];
    MTLFunctionStitchingInputNode *cInput = [[MTLFunctionStitchingInputNode alloc] initWithArgumentIndex:1];

    // Create function nodes for each function the implementation should call.
    // A function node’s output type is the return type of the Metal Shading Language function that calls it.
    
    // Get z.x.
    MTLFunctionStitchingFunctionNode *z_x = [[MTLFunctionStitchingFunctionNode alloc] initWithName:@"get_x_component"
                                                                                         arguments:@[zInput]
                                                                               controlDependencies:@[]];
    
    // Get z.y.
    MTLFunctionStitchingFunctionNode *z_y = [[MTLFunctionStitchingFunctionNode alloc] initWithName:@"get_y_component"
                                                                                         arguments:@[zInput]
                                                                               controlDependencies:@[]];
    
    // Get -z.y.
    MTLFunctionStitchingFunctionNode *negate_zY = [[MTLFunctionStitchingFunctionNode alloc] initWithName:@"negate"
                                                                                               arguments:@[z_y]
                                                                                     controlDependencies:@[]];
    
    // Initialize matrix A.
    MTLFunctionStitchingFunctionNode *init_A = [[MTLFunctionStitchingFunctionNode alloc] initWithName:@"init_A"
                                                                                            arguments:@[z_x, z_y, negate_zY, z_x]
                                                                                  controlDependencies:@[]];
    
    // Multiply matrix A by vector z.
    MTLFunctionStitchingFunctionNode *multiply_Az = [[MTLFunctionStitchingFunctionNode alloc] initWithName:@"multiply"
                                                                                                 arguments:@[init_A, zInput]
                                                                                       controlDependencies:@[]];
    
    // Calculate the final result adding or subtracting the result of (A * z) to c.
    MTLFunctionStitchingFunctionNode *output = [[MTLFunctionStitchingFunctionNode alloc]
                                                initWithName:subtract ? @"subtract" : @"add"
                                                arguments:@[multiply_Az, cInput]
                                                controlDependencies:@[]];
    
    // The output type of each node in the nodes array matches the type of the
    // node it's passed into as an argument. For example, the output type of
    // the init_A function node is float2x2 which matches the first input
    // argument type of the multiply function node, and the zInput node's output
    // type matches the float2 type of second input argument of the multiply
    // function.
    // Metal doesn’t define the behavior of the resulting function if the output
    // and argument types don't match.
    NSArray<MTLFunctionStitchingFunctionNode*> *nodes = @[z_x, z_y, negate_zY, init_A, multiply_Az];
    
    // Create the stitching graph from the input and function nodes.
    MTLFunctionStitchingGraph *graph = [[MTLFunctionStitchingGraph alloc] initWithFunctionName:@"calculate_Z"
                                                                                         nodes:nodes
                                                                                    outputNode:output
                                                                                    attributes:@[]];
    
    // Create an array of stitchable functions from the metallib.
    NSArray<id<MTLFunction>> *stitchableFunctions = @[subtract ? [metalLib newFunctionWithName:@"subtract"] : [metalLib newFunctionWithName:@"add"],
                                                      [metalLib newFunctionWithName:@"multiply"],
                                                      [metalLib newFunctionWithName:@"negate"],
                                                      [metalLib newFunctionWithName:@"get_x_component"],
                                                      [metalLib newFunctionWithName:@"get_y_component"],
                                                      [metalLib newFunctionWithName:@"init_A"]];
    
    // Create a stitched function library with the functions and graph above.
    MTLStitchedLibraryDescriptor *desc = [MTLStitchedLibraryDescriptor new];
    desc.functions = stitchableFunctions;
    desc.functionGraphs = @[graph];
    NSError *error = nil;
    id<MTLLibrary> stitchedLibrary = [_device newLibraryWithStitchedDescriptor:desc error:&error];
    NSAssert(stitchedLibrary, @"Failed to create stitched function library: %@", error);
    
    // Create a stitched function from the stitched function library.
    MTLFunctionDescriptor *functionDesc = [MTLFunctionDescriptor new];
    functionDesc.name = @"calculate_Z";
    id<MTLFunction> calculateZ = [stitchedLibrary newFunctionWithDescriptor:functionDesc error:&error];
    NSAssert(calculateZ, @"Failed to create stitched function: %@", error);
    
    return calculateZ;
}

/// Create the render pipeline state for the fractal.
- (void)createRenderStateWithFunctionsAndLibraries:(NSArray<id<MTLLibrary>>*)metalLibs
{
    NSError *error;
    
    // Load the vertex function from the library.
    id<MTLFunction> vertexFunction = [metalLibs[AAPLLibraryIndexMandelbrot] newFunctionWithName:@"vertexShader"];
    
    // Load the fragment function from the library.
    id<MTLFunction> fragmentFunction = [metalLibs[AAPLLibraryIndexMandelbrot] newFunctionWithName:@"mandlebrotFragment"];
    
    MTLLinkedFunctions *linkedFunctions = [self createLinkedFunctions:metalLibs];
    
    // Configure a pipeline descriptor to create a pipeline state.
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label = @"Simple Pipeline";
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    // The pipeline calls a function from this list of binary linked functions.
    pipelineDescriptor.fragmentLinkedFunctions = linkedFunctions;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // If "Visualization" mode is set to "Debug" in the user interface then override
    // behavior by preferentially linking to the functions in the dynamic library.
    if(useUserDylib)
    {
        id<MTLDynamicLibrary> userDylib = [self createUserDylib:pipelineDescriptor];
        pipelineDescriptor.fragmentPreloadedLibraries = @[userDylib];
    }
    
    _renderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    NSAssert(_renderPipeline, @"Failed to create render pipeline state: %@", error);
    
    [self createVisibleFunctionTable:linkedFunctions];
}

/// Create linked render functions.
- (MTLLinkedFunctions *)createLinkedFunctions:(NSArray<id<MTLLibrary>>*)metalLibs
{
    NSError *error;
    
    MTLFunctionDescriptor *functionDescriptor = [MTLFunctionDescriptor new];
    // Back-end compile functions to machine code.
    functionDescriptor.options = MTLFunctionOptionCompileToBinary;
    
    // Instantiate back-end compiled functions from the Mandelbrot metallib.
    functionDescriptor.name = @"colorInside";
    id<MTLFunction> colorInsideFunction = [metalLibs[AAPLLibraryIndexMandelbrot]
                                           newFunctionWithDescriptor:functionDescriptor
                                           error:&error];
    
    functionDescriptor.name = @"colorEscaped";
    id<MTLFunction> colorOutsideFunction = [metalLibs[AAPLLibraryIndexMandelbrot]
                                            newFunctionWithDescriptor:functionDescriptor
                                            error:&error];
    
    // Instantiate a stitched function from the Mandelbrot metallib.
    id<MTLFunction> calculateZ = [self createStitchedFunction:metalLibs[AAPLLibraryIndexMandelbrot]
                                                     subtract:useSubtraction];
    
    
    MTLLinkedFunctions *linkedFunctions = [MTLLinkedFunctions new];
    linkedFunctions.binaryFunctions = @[colorInsideFunction, colorOutsideFunction];
    // Statically link the stitched function as a private function because you don't need
    // to override its behavior with a function loaded from a Metal dynamic library.
    linkedFunctions.privateFunctions = @[calculateZ];
    
    return linkedFunctions;
}

/// Create optional user dylib.
- (id<MTLDynamicLibrary>)createUserDylib:(MTLRenderPipelineDescriptor *)pipelineDescriptor
{
    NSError *error;
    
    NSString *userDylibPath = [[NSBundle mainBundle] pathForResource:@"AAPLUserCompiledFunction" ofType:@"metal"];
    NSAssert(userDylibPath, @"Invalid path to dynamic metal library.");
    NSURL *userDylibURL = [NSURL fileURLWithPath:userDylibPath];
    MTLCompileOptions *compileOptions = [MTLCompileOptions new];
    compileOptions.installName = @"@executable_path/libUserDylib.metallib";
    compileOptions.libraryType = MTLLibraryTypeDynamic;
    
    id<MTLLibrary> userLibrary = [_device newLibraryWithSource:
                                  [NSString stringWithContentsOfURL:userDylibURL                                encoding:NSUTF8StringEncoding
                                                              error:&error]
                                                       options:compileOptions
                                                         error:&error];
    NSAssert(userLibrary && !error, @"Unable to create new metal library from source: %@", error);
    
    id<MTLDynamicLibrary> userDylib = [_device newDynamicLibrary:userLibrary error:&error];
    NSAssert(userDylib && !error, @"Unable to create new dynamic metal library from source: %@", error);
    
    return userDylib;
}

- (void)createVisibleFunctionTable:(MTLLinkedFunctions *)linkedFunctions
{
    MTLVisibleFunctionTableDescriptor *vftDescriptor = [MTLVisibleFunctionTableDescriptor new];
    vftDescriptor.functionCount = 2;
    
    // Create visible function table with capacity for two functions.
    _visibleFunctionTable = [_renderPipeline newVisibleFunctionTableWithDescriptor:vftDescriptor
                                                                            stage:MTLRenderStageFragment];
    NSAssert(_visibleFunctionTable, @"Failed to create the visible function table.");
    
    // Get function handles to the binary linked functions and assign them at visible function table indices.
    [_visibleFunctionTable setFunction:[_renderPipeline functionHandleWithFunction:linkedFunctions.binaryFunctions[0]
                                                                             stage:MTLRenderStageFragment] atIndex:0];
    [_visibleFunctionTable setFunction:[_renderPipeline functionHandleWithFunction:linkedFunctions.binaryFunctions[1]
                                                                             stage:MTLRenderStageFragment] atIndex:1];
}

#pragma mark MTKViewDelegate

/// Called whenever view changes orientation or layout is changed.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/// Called whenever the view needs to render.
- (void)drawInMTKView:(nonnull MTKView*)view
{
    static const AAPLVertex triangleVertices[] =
    {
        // 2D positions,   texture coordinates
        { { -500,  -500 }, { -2, -2 } },
        { {  500,  -500 }, {  2, -2 } },
        { { -500,   500 }, { -2,  2 } },
        { {  500,   500 }, {  2,  2 } }
    };
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil)
    {
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        commandBuffer.label = [NSString stringWithFormat:@"Render CommandBuffer"];
        
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer
                                                     renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"Render Encoder";
        [renderEncoder pushDebugGroup:@"Render fractal"];
        
        [renderEncoder setRenderPipelineState:_renderPipeline];
        
        // Pass in the parameter data.
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:AAPLVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:AAPLVertexInputIndexViewportSize];
        
        FractalConfiguration fractalConfig = { .iterations = iterations };
        [renderEncoder setFragmentBytes:&fractalConfig
                                 length:sizeof(FractalConfiguration)
                                atIndex:0];
        
        // Bind the visible function table to a buffer with the given buffer index.
        [renderEncoder setFragmentVisibleFunctionTable:_visibleFunctionTable atBufferIndex:1];
        
        // Draw the fractal.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                          vertexStart:0
                          vertexCount:4];
        
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        
        // Schedule presentation after the GPU finishes rendering to the drawable.
        [commandBuffer presentDrawable:view.currentDrawable];
        
        [commandBuffer commit];
    }
}

@end
