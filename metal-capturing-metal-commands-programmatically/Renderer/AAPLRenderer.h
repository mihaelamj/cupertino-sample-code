/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the renderer class that performs Metal setup and per-frame rendering.
*/

@import MetalKit;
#import "AAPLCaptureManager.h"

@interface AAPLRenderer : NSObject <MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@property (readwrite, nonatomic) AAPLCaptureManager* _Nonnull captureManager;

@end

