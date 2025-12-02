/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that renders a set of thin shards with MSAA.
*/

@import MetalKit;
@import simd;

#import "AAPLConfig.h"

/// A class responsible for updating and rendering the view.
@interface AAPLRenderer : NSObject

/// A Boolean value that causes the thin shards to rotate.
@property (nonatomic) BOOL              animated;
/// A Boolean value that tells the renderer to apply MSAA.
@property (nonatomic) BOOL              antialiasingEnabled;
/// The number of samples to use for antialiasing.
@property (nonatomic) NSUInteger        antialiasingSampleCount;
/// An enumerated value that tells the renderer how to resolve the MSAA texture to a normal texture.
@property (nonatomic) AAPLResolveOption resolveOption;
/// A Boolean value that tells the renderer to update the antialiasing render pipeline state objects.
@property (nonatomic) BOOL              antialiasingOptionsChanged;
/// A value that tells the renderer how to adjust the resolution of the render texture.
@property (nonatomic) float             renderingQuality;

/// A Boolean value that tells the renderer if the device supports the tile-based resolve.
@property (readonly, nonatomic) BOOL    supportsTileShaders;
/// A Boolean value that tells the renderer if it should use the tile-based resolve.
@property (nonatomic) BOOL              resolvingOnTileShaders;

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat;

- (void)drawInMTKView:(nonnull MTKView*)view;

- (void)drawableSizeWillChange:(CGSize)drawableSize;

- (void)createMultisampleTexture;

- (void)updateResolveOptionInPipeline;

@end
