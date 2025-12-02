/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the app's MetalKit view delegate.
*/

#import "MetalKitViewDelegate.h"

#import "MetalRenderer.h"
#import "Metal4Renderer.h"

/// A class that renders each of the app's video frames.
@implementation MetalKitViewDelegate
{
@protected
    id<Renderer> renderer;
    MTKView *metalKitView;
}

/// Creates a delegate for a view.
///
/// The method detects whether the system supports Metal 4 and creates an
/// instance of the appropriate renderer type.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    renderer = nil;
    metalKitView = nil;

    self = [super init];
    if (nil == self) { return nil; }

    metalKitView = view;

#if !TARGET_OS_SIMULATOR
    if (@available(iOS 26.0, tvOS 26.0, macOS 26.0, *)) {
        if ([view.device supportsFamily:MTLGPUFamilyMetal4]) {
            // Create a Metal 4 renderer instance for the app's lifetime.
            renderer = [[Metal4Renderer alloc] initWithMetalKitView:view];

            return self;
        }
    }
#endif

    // Create a Metal renderer instance for the app's lifetime.
    renderer = [[MetalRenderer alloc] initWithMetalKitView:view];
    NSAssert(renderer, @"The delegate can't create a renderer instance.");

    return self;
}

/// Notifies the app when the system adjusts the size of its viewable area.
- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize) size
{
    NSAssert(metalKitView == view, @"The delegate only works with one view.");
    [renderer updateViewportSize:size];
}

/// Notifies the app when the system is ready draw a frame into a view.
- (void) drawInMTKView:(nonnull MTKView *) view
{
    NSAssert(metalKitView == view, @"The delegate only works with one view.");
    [renderer renderFrameToView:view];
}

@end
