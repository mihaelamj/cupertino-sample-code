/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the Metal renderer's methods that set up the render's resources.
*/

#import "MetalRenderer.h"

@interface MetalRenderer (Setup)

- (nonnull NSArray<id<MTLBuffer>> *) makeTriangleDataBuffers:(NSUInteger) count;

@end
