/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform Metal rendering view controller.
*/

#import "AAPLRenderViewController.h"
#import "AAPLConfigurationViewController.h"
#include "AAPLRenderer.h"

#if defined(TARGET_IOS)
#include "AAPLSplitViewController.h"
#endif

@implementation AAPLRenderViewController
{
    MTKView *_view;
    
    AAPLRenderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MTKView *)self.view;

#if defined(TARGET_IOS)
    _view.device = MTLCreateSystemDefaultDevice();
    NSAssert(_view.device, @"Metal isn't supported on this device.");
    
    if(@available(iOS 15.0, *))
    {
        NSAssert(_view.device.supportsDynamicLibraries,
                 @"Dynamic libraries aren't supported on this device. Use a device with an A13 or newer.");
        NSAssert(_view.device.supportsRenderDynamicLibraries,
                 @"Render dynamic libraries aren't supported on this device. Use a device with an A13 or newer.");
        NSAssert(_view.device.supportsFunctionPointersFromRender,
                 @"This device doesn't support using function pointers from render pipeline stages.");
    }
    else
    {
        NSLog(@"Metal features required for this sample are supported only on iOS 15 and higher.");
        return;
    }
#else
    _view.device = [self selectMetalDevice];
    NSAssert(_view.device, @"Metal features required for this sample aren't supported on this device.");
#endif

    _view.framebufferOnly = NO;
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
    NSAssert(_renderer, @"Renderer failed initialization");

#if defined(TARGET_IOS)
    CGFloat contentScaleFactor = _view.contentScaleFactor;
    [_renderer mtkView:_view drawableSizeWillChange:
     CGSizeMake(_view.bounds.size.width * contentScaleFactor,
                _view.bounds.size.height * contentScaleFactor)];
#else
    CGFloat backingScaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    [_renderer mtkView:_view drawableSizeWillChange:
     CGSizeMake(_view.bounds.size.width * backingScaleFactor,
                _view.bounds.size.height * backingScaleFactor)];
#endif
    
    _view.delegate = _renderer;
}

#if defined(TARGET_IOS)
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Find the split view controller.
    UIViewController *parentViewController = [self parentViewController];
    while(parentViewController != nil &&
          ![parentViewController isKindOfClass:[AAPLSplitViewController class]])
    {
        parentViewController = [parentViewController parentViewController];
    }
    NSAssert(parentViewController, @"Could not establish expected parent view controller");
    AAPLSplitViewController *splitViewController = (AAPLSplitViewController *)parentViewController;
    
    // Find the configuration view controller.
    NSArray<__kindof UIViewController *> *viewControllers = [splitViewController viewControllers];
    AAPLConfigurationViewController *configViewController;
    for(UIViewController *viewController in viewControllers)
    {
        if([viewController isKindOfClass:[AAPLConfigurationViewController class]])
        {
            configViewController = (AAPLConfigurationViewController *)viewController;
            break;
        }
    }
    if(configViewController != nil)
    {
        configViewController.renderViewController = self;
    }
}
#else
- (void)viewWillAppear
{
    [super viewWillAppear];
    
    AAPLConfigurationViewController *configViewController = (AAPLConfigurationViewController *)[[[((NSSplitViewController *)[self parentViewController])
                                  splitViewItems]
                                 firstObject]
                                viewController];
    if(configViewController != nil)
    {
        configViewController.renderViewController = self;
    }
}

- (id<MTLDevice>)selectMetalDevice
{
    NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
    // Search for high-powered devices that support dynamic libraries and render function pointers.
    for(id<MTLDevice> device in devices)
    {
        if(!device.isLowPower &&
           device.supportsDynamicLibraries &&
           device.supportsRenderDynamicLibraries &&
           device.supportsFunctionPointersFromRender)
        {
            return device;
        }
    }
    
    return nil;
}
#endif

- (void)updateRendererWith:(BOOL)isDebugVisualization
      subtractionOperation:(BOOL)useSubtraction
                iterations:(int)iterations
{
    [_renderer updateRenderStateFor:_view
                  withVisualization:isDebugVisualization
               subtractionOperation:useSubtraction
                         iterations:iterations];
}

@end
