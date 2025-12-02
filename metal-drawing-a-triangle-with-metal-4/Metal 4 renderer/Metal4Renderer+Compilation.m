/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the Metal 4 renderer's method that compiles a render pipeline.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer+Compilation.h"

@implementation Metal4Renderer (Compilation)

/// Creates the renderer's pipeline state that works with a specific pixel format.
///
/// - Parameter colorPixelFormat: A pixel size and layout configuration the
/// method applies to the render pipeline it compiles.
- (id<MTLRenderPipelineState>) compileRenderPipeline:(MTLPixelFormat) colorPixelFormat
{
    /// A Metal 4 compiler instance with a default configuration.
    id<MTL4Compiler> compiler = [self createDefaultMetalCompiler];

    /// A configuration for the render pipeline the method compiles.
    MTL4RenderPipelineDescriptor* descriptor;
    descriptor = [self configureRenderPipeline: colorPixelFormat];

    /// An optional configuration that stores references to binary archives.
    MTL4CompilerTaskOptions *compilerTaskOptions;
    compilerTaskOptions = [self configureCompilerTaskOptions];

    /// A reference to an error instance the compiler assigns
    /// if it can't compile the render pipeline.
    NSError *error = nil;

    // Compile a render pipeline state.

    id<MTLRenderPipelineState> renderPipelineState;
    renderPipelineState = [compiler newRenderPipelineStateWithDescriptor:descriptor
                                                     compilerTaskOptions:compilerTaskOptions
                                                                   error:&error];

    // Verify the compiler creates the pipeline state successfully.
    // Xcode turns on Metal API Validation by default for debug builds.
    NSAssert(nil != renderPipelineState,
             @"The compiler can't create a pipeline state due to: %@\n%@", error,
             @"Check the descriptor's configuration and turn on Metal API validation for more information."
             );

    return renderPipelineState;
}

- (id<MTL4Compiler>) createDefaultMetalCompiler
{
    NSError *error = nil;

    id<MTL4Compiler> compiler;
    compiler = [self.device newCompilerWithDescriptor:[MTL4CompilerDescriptor new]
                                                error:&error];

    if (nil == compiler) {
        NSString *errorString;
        errorString = @"The Metal device can't create a compiler";
        errorString = [errorString stringByAppendingString:
                       nil == error ? @"." : @": %@\n"];

        NSAssert(false, errorString, error);
    }

    return compiler;
}

/// Creates and configures the renderer's only render pipeline.
///
/// - Parameter colorPixelFormat: An output data format that the new render pipeline produces.
- (MTL4RenderPipelineDescriptor*) configureRenderPipeline:(MTLPixelFormat) colorPixelFormat
{
    MTL4RenderPipelineDescriptor *renderPipelineDescriptor;
    renderPipelineDescriptor = [MTL4RenderPipelineDescriptor new];
    renderPipelineDescriptor.label = @"Basic Metal 4 render pipeline";

    // Set the pixel format, the vertex shader, and fragment shader for the configuration.
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat;
    renderPipelineDescriptor.vertexFunctionDescriptor = [self makeVertexShaderConfiguration];
    renderPipelineDescriptor.fragmentFunctionDescriptor = [self makeFragmentShaderConfiguration];

    return renderPipelineDescriptor;
}

/// Creates a library function descriptor for the app's vertex shader.
///
/// Xcode compiles the `vertexShader` GPU function in the `Shaders.metal` source
/// code file into the app's default library.
- (MTL4LibraryFunctionDescriptor*) makeVertexShaderConfiguration
{
    MTL4LibraryFunctionDescriptor *vertexFunction;
    vertexFunction = [MTL4LibraryFunctionDescriptor new];
    vertexFunction.library = self.defaultLibrary;
    vertexFunction.name = @"vertexShader";

    return vertexFunction;
}

/// Creates a library function descriptor for the app's fragment shader.
///
/// Xcode compiles the `fragmentShader` GPU function in the `Shaders.metal` source
/// code file into the app's default library.
- (MTL4LibraryFunctionDescriptor*) makeFragmentShaderConfiguration
{
    MTL4LibraryFunctionDescriptor *fragmentFunction;
    fragmentFunction = [MTL4LibraryFunctionDescriptor new];
    fragmentFunction.library = self.defaultLibrary;
    fragmentFunction.name = @"fragmentShader";

    return fragmentFunction;
}

- (MTL4CompilerTaskOptions*) configureCompilerTaskOptions
{
    // Retrieve the file URL for the binary archive in the app's main bundle.
    NSURL* archiveURL = [[NSBundle mainBundle] URLForResource:@"archive"
                                                withExtension:@"metallib"];

    if (nil == archiveURL) {
        return nil;
    }

    NSError *error = nil;
    // Load the default binary archive that stores the app's shaders that Xcode precompiles.
    id<MTL4Archive> defaultArchive = [self.device newArchiveWithURL:archiveURL
                                                              error:&error];

    // Check for an error state.
    if (nil == defaultArchive) {
        NSString *errorString;
        errorString = @"The Metal device can't create a new archive from a URL: ";
        errorString = [errorString stringByAppendingString:archiveURL.debugDescription];
        errorString = [errorString stringByAppendingString: nil == error ? @"." : @"\n Error: %@\n"];

        NSLog(errorString, archiveURL, error);
        return nil;
    }

    // Configure the task options to look in the default archive first.
    MTL4CompilerTaskOptions *compilerTaskOptions = [MTL4CompilerTaskOptions new];
    compilerTaskOptions.lookupArchives = @[defaultArchive];

    return compilerTaskOptions;
}
@end

#endif
