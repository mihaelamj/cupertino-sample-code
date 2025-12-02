/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the renderer class that performs Metal setup and per-frame rendering.
*/

#import <MetalKit/MetalKit.h>
#import "AAPLImage.h"

typedef struct AAPLPixelBGRA8Unorm {
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t alpha;
} AAPLPixelBGRA8Unorm;

@interface AAPLRenderer : NSObject<MTKViewDelegate>

@property BOOL drawOutline;
@property CGRect outlineRect;

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (nonnull AAPLImage*)renderAndReadPixelsFromView:(nonnull MTKView*)view withRegion:(CGRect)region;

@end
