/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that performs Metal setup and per-frame rendering.
*/

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAMetalDisplayLink.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "GameState.h"

@interface Renderer : NSObject

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat;

/// Draws a graphics image for the game to the view.
- (void)renderTo:(nonnull CAMetalLayer*)metalLayer
            with:(CAMetalDisplayLinkUpdate *_Nonnull)update
              at:(CFTimeInterval)deltaTime;

/// Responds to the drawable's size or orientation changes.
- (void)drawableResize:(CGSize)drawableSize;

@property (nonatomic, nonnull) GameState *state;

@property (nonatomic) NSUInteger      sampleCount;
@property (nonatomic) MTLPixelFormat  colorPixelFormat;
@property (nonatomic) MTLPixelFormat  depthStencilPixelFormat;
@property (nonatomic) MTLTextureUsage depthStencilAttachmentTextureUsage;
@property (nonatomic) MTLStorageMode  depthStencilStorageMode;
@property (nonatomic, nonnull) CGColorSpaceRef colorspace;

@end
