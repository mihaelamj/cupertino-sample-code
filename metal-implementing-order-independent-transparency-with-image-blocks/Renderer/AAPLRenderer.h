/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The renderer class's header.
*/

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface AAPLRenderer : NSObject <MTKViewDelegate>

- (nonnull instancetype) initWithMetalKitView:(nonnull MTKView*)mtkView;

@property (nonatomic, readonly) BOOL supportsOrderIndependentTransparency;

@property (nonatomic) BOOL enableOrderIndependentTransparency;

@property (nonatomic) BOOL enableRotation;

/// The main GPU of the device.
@property (nonatomic, readonly, nonnull) id<MTLDevice> device;

/// The view that shows the app's rendered Metal content.
@property (nonatomic, readonly, nonnull) MTKView* mtkView;

@end

NS_ASSUME_NONNULL_END
