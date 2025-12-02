/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's cross-platform view controller.
*/

#import "ViewController.h"
#import "Metal4Renderer.h"

@implementation ViewController
{
    MTKView *view;
    Metal4Renderer *renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set the view to use the default device.
    view = (MTKView *)self.view;
    view.device = MTLCreateSystemDefaultDevice();
    NSAssert(view.device, @"This system doesn't support Metal.");

    if ([view.device supportsFamily:MTLGPUFamilyMetal4]) {
        // Create a Metal 4 renderer instance for the app's lifetime.
        renderer = [[Metal4Renderer alloc] initWithView:view];
        NSAssert(renderer, @"The app couldn't create a renderer.");
    }
    else
    {
        NSAssert(view.device, @"This system doesn't support Metal 4.");
    }

    // Initialize our renderer with the view size.
    [renderer mtkView:view drawableSizeWillChange:view.drawableSize];

    view.delegate = renderer;
}

@end
