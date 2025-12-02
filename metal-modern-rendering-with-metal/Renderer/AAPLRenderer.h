/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for a renderer class, which manages render state and performs per-frame rendering.
*/

#import <MetalKit/MetalKit.h>
#import <simd/types.h>

@class AAPLScene;
@class AAPLCamera;

#if SUPPORT_ON_SCREEN_SETTINGS
@class AAPLSettingsTableViewController;
#endif

struct AAPLInput;

// Data stored for each view to be rendered.
struct AAPLFrameViewData
{
    // Camera data for view.
    _Nonnull id <MTLBuffer> cameraParamsBuffer;
    // Culling camera params for view.
    _Nonnull id <MTLBuffer> cullParamBuffer;
};

// Options for encoding rendering.
typedef NS_ENUM(uint32_t, AAPLRenderMode)
{
    AAPLRenderModeDirect,   // CPU encoding of draws with a `MTLRenderCommandEncoder`.
    AAPLRenderModeIndirect, // GPU encoding of draws with an `MTLIndirectCommandBuffer`.
};

// Our platform independent renderer class.
@interface AAPLRenderer : NSObject

// Initialization.
-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

// Updates the state for frame state based on the current input.
- (void)updateFrameState:(const AAPLInput&)input;

// Draws the the view.
- (void)drawInMTKView:(nonnull MTKView *)view;

// Resizes internal structures to the specified resolution.
- (void)resize:(CGSize)size;

#if SUPPORT_ON_SCREEN_SETTINGS
- (void)registerWidgets:(nonnull AAPLSettingsTableViewController*)settingsController;
#endif

@property BOOL renderUI;
@property (readonly, nonnull) NSString* info;

@end

