/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform view controller.
*/
#import "ViewController.h"
#import "Renderer.h"

@implementation ViewController
{
    MTKView *_view;

    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

#if TARGET_OS_IPHONE
    _view.device = MTLCreateSystemDefaultDevice();
#else
    NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();

    id<MTLDevice> selectedDevice;

    for(id<MTLDevice> device in devices)
    {
        if(device.supportsRaytracing)
        {
            if(!selectedDevice || !device.isLowPower)
            {
                selectedDevice = device;
            }
        }
    }
    _view.device = selectedDevice;

    NSLog(@"Selected Device: %@", _view.device.name);
#endif

    // The device must support Metal and ray tracing.
    NSAssert(_view.device && _view.device.supportsRaytracing,
             @"Ray tracing isn't supported on this device");
    
#if defined(MTL_SUPPORT_PRIMITIVE_MOTION_QUERY) && MTL_SUPPORT_PRIMITIVE_MOTION_QUERY
    BOOL usePrimitiveMotion = _view.device.supportsPrimitiveMotionBlur;
#else
    BOOL usePrimitiveMotion = false;
#endif

#if TARGET_OS_IPHONE
    _view.backgroundColor = UIColor.blackColor;
#endif
    _view.colorPixelFormat = MTLPixelFormatRGBA16Float;

    Scene *scene = [Scene newMotionBlurSceneWithDevice:_view.device
                                    usePrimitiveMotion:usePrimitiveMotion];

    _renderer = [[Renderer alloc] initWithDevice:_view.device
                                           scene:scene
                              usePrimitiveMotion:usePrimitiveMotion];

    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];

    _view.delegate = _renderer;
}

@end
