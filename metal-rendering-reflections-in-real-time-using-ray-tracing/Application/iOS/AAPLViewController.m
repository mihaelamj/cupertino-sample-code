/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the iOS view controller.
*/

#import "AAPLViewController.h"
#import "AAPLRenderer.h"
#import <MetalKit/MetalKit.h>

@implementation AAPLViewController
{
    MTKView *_view;

    AAPLRenderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_loadingSpinner startAnimating];
    
    _view = (MTKView *)self.view;
    _view.layer.backgroundColor = [UIColor colorWithRed:0.65 green:0.65 blue:0.65 alpha:1.0].CGColor;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.preferredFramesPerSecond = 30;

    NSAssert(_view.device, @"Metal is not supported on this device");

    dispatch_queue_t q = dispatch_get_global_queue( QOS_CLASS_USER_INITIATED, 0 );
    
    CGSize size = _view.bounds.size;
    __weak AAPLViewController* weakSelf = self;
    dispatch_async( q, ^(){
        AAPLViewController* strongSelf;
        if ( (strongSelf = weakSelf) )
        {
            strongSelf->_renderer = [[AAPLRenderer alloc] initWithMetalKitView:strongSelf->_view size:size];

            NSAssert(strongSelf->_renderer, @"Renderer failed initialization");

            dispatch_async( dispatch_get_main_queue(), ^(){
                AAPLViewController* innerStrongSelf;
                if ( (innerStrongSelf = weakSelf) )
                {
                    [innerStrongSelf->_loadingSpinner stopAnimating];
                    innerStrongSelf->_loadingLabel.hidden = YES;

                    [innerStrongSelf->_renderer mtkView:innerStrongSelf->_view
                                 drawableSizeWillChange:innerStrongSelf->_view.drawableSize];

                    innerStrongSelf->_view.delegate = innerStrongSelf->_renderer;
                }
            });
        }
    } );

}

@end
