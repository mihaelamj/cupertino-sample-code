/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the Metal 4 renderer's methods that set up the render's resources.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer.h"

@interface Metal4Renderer (Setup)

- (nonnull NSArray<id<MTLBuffer>> *) makeTriangleDataBuffers:(NSUInteger) count;

- (nonnull id<MTL4ArgumentTable>) makeArgumentTable;

- (nonnull id<MTLResidencySet>) makeResidencySet;

- (nonnull NSArray<id<MTL4CommandAllocator>> *) makeCommandAllocators:(NSUInteger) count;

@end

#endif
