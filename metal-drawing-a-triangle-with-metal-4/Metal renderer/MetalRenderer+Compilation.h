/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the Metal renderer's method that compiles a render pipeline.
*/

#import "MetalRenderer.h"

@interface MetalRenderer (Compilation)

- (id<MTLRenderPipelineState>) compileRenderPipeline:(MTLPixelFormat) colorPixelFormat;

@end
