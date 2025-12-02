/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform game view controller.
*/

#import "GameViewController.h"
#import "Renderer.h"

#import "GameInput.h"

@implementation GameViewController
{
    /// A queue to initialize the renderer asynchronously from the main thread.
    dispatch_queue_t _dispatch_queue;
    
    GameView *_gameView;
    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /// A queue to initialize the renderer asynchronously from the main thread.
    _dispatch_queue = dispatch_queue_create("com.example.apple-samplecode.FramePacing", DISPATCH_QUEUE_CONCURRENT);
    
    __block GameView *view = (GameView *)self.view;
    if (!view)
    {
        NSLog(@"The view attached to GameViewController isn't an GameView.");
        return;
    }
    _gameView = view;
    _gameView.delegate = self;
    
    // Initialize the app asynchronously to avoid blocking the main thread.
    dispatch_async(_dispatch_queue, ^{
        // Select the device to render with.
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device)
        {
            NSLog(@"Metal isn't supported on this device.");
            self.view = [[PlatformView alloc] initWithFrame:self.view.frame];
            return;
        }
        view.metalLayer.device = device;
        
        // Initialize the renderer.
        Renderer* renderer = [[Renderer alloc] initWithMetalDevice:device
                                               drawablePixelFormat:MTLPixelFormatRGB10A2Unorm];
        if (!renderer)
        {
            NSLog(@"The renderer couldn't be initialized.");
            return;
        }
        
        // Give the renderer the current view's size.
        [renderer drawableResize:view.metalLayer.drawableSize];
        
        // Initialize the renderer-dependent view properties.
        view.metalLayer.pixelFormat = renderer.colorPixelFormat;
        view.metalLayer.colorspace = renderer.colorspace;
        renderer.state.gameInput = [GameInput new];
        
        self->_renderer = renderer;
    });
}

/// Draws the graphics frame.
- (void)renderTo:(nonnull CAMetalLayer *)layer
            with:(CAMetalDisplayLinkUpdate *_Nonnull)update
              at:(CFTimeInterval)deltaTime
{
    if (!_renderer)
    {
        return;
    }
    
    [_renderer renderTo:layer with:update at:deltaTime];
}

///// Responds to changes to the drawable's size or orientation changes.
- (void)drawableResize:(CGSize)size
{
    [_renderer drawableResize:size];
}

#if TARGET_IOS
/// Hides the Home indicator button automatically.
- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}
#endif

#if TARGET_MACOS
/// Makes the view controller the first responder to receive keyboard events.
- (void)viewDidAppear
{
    [_gameView.window makeFirstResponder:self];
}

/// Receives the keydown events to avoid system beeps.
///
/// The `GameInputKeyboardMouse` class handles keyboard events.
- (void)keyDown:(NSEvent *)event
{
    // Reference the parameter to avoid an unused parameter warning.
    (void)(event);
}

/// Receives the keyup events to avoid system beeps.
///
/// The `GameInputKeyboardMouse` class handles keyboard events.
- (void)keyUp:(NSEvent *)event
{
    // Reference the parameter to avoid an unused parameter warning.
    (void)(event);
}
#endif

@end
