/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class tracking source (asset) textures.
*/

#import "AAPLConfig.h"

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

@class AAPLTextureData;

//----------------------------------------------------

NSUInteger calculateMinMip(const AAPLTextureData* _Nonnull textureAsset, NSUInteger maxTextureSize);

//----------------------------------------------------

@interface AAPLTextureManager : NSObject

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                          commandQueue:(nonnull id<MTLCommandQueue>)commandQueue
                              heapSize:(NSUInteger)heapSize
                  permanentTextureSize:(NSUInteger)permanentTextureSize
                        maxTextureSize:(NSUInteger)maxTextureSize
                     useSparseTextures:(BOOL)useSparseTextures;

- (void)update:(NSUInteger)frameIndex deltaTime:(float)deltaTime forceTextureSize:(NSUInteger)forceTextureSize;

- (nullable id<MTLTexture>)getTexture:(unsigned int)hash
                        outCurrentMip:(nullable NSUInteger*)outCurrentMip;

- (void)addTextures:(nonnull NSArray<AAPLTextureData*>*)textures data:(nonnull NSData *)data maxTextureSize:(NSUInteger)maxTextureSize;

- (void)makeResidentForEncoder:(nonnull id<MTLRenderCommandEncoder>)encoder;

#if USE_TEXTURE_STREAMING
- (void)setRequiredMip:(unsigned int)hash mipLevel:(NSUInteger)mipLevel;
- (void)setRequiredMip:(unsigned int)hash screenArea:(float)screenArea;
#endif

#if SUPPORT_PAGE_ACCESS_COUNTERS
- (void)updateAccessCounters:(NSUInteger)frameIndex cmdBuffer:(nonnull id<MTLCommandBuffer>)cmdBuffer;
#endif

@property (readonly, nonnull) NSString* info;

#if SUPPORT_PAGE_ACCESS_COUNTERS
@property (readonly) bool usePageAccessCounters;
#endif

@end
