/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the class that reads the texture data from a KTX file.
*/
#pragma once

#import <Metal/Metal.h>

/// The class configuring a KTX texture file for memory-mapped reading.
@interface AAPLStreamedTextureDataBacking : NSObject

/// Sets the current KTX file to read from.
- (instancetype)initWithKTXPath:(NSURL*)path;

/// Returns texture region based on its mipmap level.
- (MTLRegion)calculateMipmapRegion:(NSUInteger)mipmap;

/// The path to the KTX texture file.
@property (nonatomic, readonly) NSURL* path;

/// True if the texture is memory mapped.
@property (nonatomic, readonly) bool loaded;

/// Width of the texture.
@property (nonatomic, readonly) NSUInteger width;

/// Height of the texture.
@property (nonatomic, readonly) NSUInteger height;

/// The number of mipmap levels.
@property (nonatomic, readonly) NSUInteger mipmapLevelCount;

/// The pixel format of the pixel data.
@property (nonatomic, readonly) MTLPixelFormat pixelFormat;

/// The block size of the pixel data.
@property (nonatomic, readonly) NSUInteger blockSize;

/// The number of bytes per block of pixel data.
@property (nonatomic, readonly) NSUInteger bytesPerBlock;

/// Array of the mipmap offsets of the texture.
@property (nonatomic, readonly) NSUInteger* mipmapOffsets;

/// Array of the mipmap lengths of the texture.
@property (nonatomic, readonly) NSUInteger* mipmapLengths;

/// Pixel data of the texture.
@property (nonatomic, readonly) NSData* textureData;

@end
