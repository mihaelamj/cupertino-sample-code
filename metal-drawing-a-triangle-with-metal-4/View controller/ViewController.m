/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the cross-platform view controller.
*/

#import "ViewController.h"
#import "MetalKitViewDelegate.h"

@implementation ViewController
{
    MTKView *view;
    MetalKitViewDelegate *delegate;
}

- (void) viewDidLoad
{
    // Call the super class's method first.
    [super viewDidLoad];

    // Store a reference to the app's main view.
    view = (MTKView *)self.view;

    // Set the view's device property to the system's default Metal device.
    view.device = MTLCreateSystemDefaultDevice();
    NSAssert(view.device, @"Metal doesn't support this device.");

    delegate = [[MetalKitViewDelegate alloc] initWithMetalKitView:view];
    NSAssert(delegate, @"The view controller can't make a delegate for the MetalKit view.");

    view.delegate = delegate;
}

@end
