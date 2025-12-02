/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the Metal renderer's method that compiles a render pipeline.
*/

#import "MetalRenderer+Compilation.h"

@implementation MetalRenderer (Compilation)

/// Creates the renderer's pipeline state that works with a specific pixel format.
///
/// - Parameter colorPixelFormat: A pixel size and layout configuration the
/// method applies to the render pipeline it compiles.
- (id<MTLRenderPipelineState>) compileRenderPipeline:(MTLPixelFormat) colorPixelFormat
{
    /// A configuration for the render pipeline the method compiles.
    MTLRenderPipelineDescriptor *renderPipelineDescriptor;
    renderPipelineDescriptor = [self configureRenderPipeline:colorPixelFormat];

    // Compile a render pipeline state with the device method.
    NSError *error = nil;
    id<MTLRenderPipelineState> renderPipelineState;
    renderPipelineState= [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                     error:&error];

    // Verify the device creates the pipeline state successfully.
    // Xcode turns on Metal API Validation by default for debug builds.
    NSAssert(nil != renderPipelineState,
             @"The device can't compile a pipeline state: %@\n%@", error,
             @"Check the descriptor's configuration and turn on Metal API validation for more information."
             );

    return renderPipelineState;
}

/// Creates and configures the renderer's only render pipeline.
///
/// - Parameter colorPixelFormat: An output data format that the new render pipeline produces.
- (MTLRenderPipelineDescriptor*) configureRenderPipeline:(MTLPixelFormat) colorPixelFormat
{
    // Load all of the project's shaders,
    // which Xcode compiles at build time into the default library.
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    // Configure a pipeline descriptor that configures a pipeline state.
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    renderPipelineDescriptor.label = @"Basic Metal render pipeline";
    renderPipelineDescriptor.vertexFunction = vertexFunction;
    renderPipelineDescriptor.fragmentFunction = fragmentFunction;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat;

    return renderPipelineDescriptor;
}

@end
