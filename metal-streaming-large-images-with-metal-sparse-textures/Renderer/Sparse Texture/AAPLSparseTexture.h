/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the class that streams a sparse texture.
*/
#pragma once

#import <Metal/Metal.h>

@interface AAPLSparseTexture : NSObject

/// Initialize the sparse texture with the needed Metal objects, a path to the texture, and the heap size.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                  path:(nonnull NSURL*)path
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                              heapSize:(NSUInteger)heapSize;

/// Update the sparse texture for the current frameIndex.
- (void)update:(NSUInteger)frameIndex;

/// Maps all tiles that need residency in the sparse texture and blits the corresponding tiles.
- (void)mapAndBlitTiles;

@property (nonnull, readonly) id<MTLTexture> sparseTexture;

/// The residency buffer that keeps track of which region and which MIP have been mapped with texture data.
@property (nonnull, readonly) id<MTLBuffer> residencyBuffer;

/// The size, in tiles, of the finest and largest mipmaps.
@property (readonly) MTLSize sizeInTiles;

/// Info string is used by the UI with memory usage about the sparse texture.
@property (nonatomic, nonnull) NSString* infoString;

@end
