/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller.
*/

#import "AAPLViewController.h"
#import "AAPLSettingsTableViewController.h"

#import "AAPLInput.h"
#import "AAPLRenderer.h"

#import <simd/simd.h>

@implementation AAPLView

// signal that we want our window be the first responder of user inputs
- (BOOL)acceptsFirstResponder
{
    return YES;

}

#if !(TARGET_OS_IPHONE)
- (void)awakeFromNib
{
    // on osx, create a tracking area to keep track of the mouse movements and events
    NSTrackingAreaOptions options = (NSTrackingActiveAlways
                                     | NSTrackingInVisibleRect
                                     | NSTrackingMouseEnteredAndExited
                                     | NSTrackingMouseMoved);

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                        options:options
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    return YES;
}

#endif
@end

@implementation AAPLViewController
{
#if TARGET_OS_IPHONE
    __weak IBOutlet UILabel         *_infoLabel;
    __weak IBOutlet UIView          *_settingsView;
    __weak IBOutlet UISwitch        *_settingsSwitch;
    AAPLSettingsTableViewController *_settingsController;
#else
    __weak IBOutlet NSTextField     *_infoLabel;
#endif

    AAPLRenderer*   _renderer;
    AAPLInput       _input;

#if TARGET_OS_IPHONE
    NSMutableDictionary<NSValue*,AAPLTouch*>* _touches;
#endif

    AAPLView * _aaplView;
}

#if TARGET_OS_IPHONE
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

#if TARGET_OS_IPHONE
- (IBAction)toggleSettings:(id)sender
{
    if(_settingsView != nil)
        _settingsView.hidden = ![sender isOn];
}
#endif

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    for(UITouch* uiTouch in touches)
    {
        CGPoint location = [uiTouch locationInView:nil];
        CGSize size = uiTouch.view.bounds.size;

        simd::float2 pos = simd::make_float2(location.x / size.width, location.y / size.height);

        AAPLTouch* touch    = [AAPLTouch new];
        touch.pos           = pos;
        touch.startPos      = touch.pos;

        NSValue* key = [NSValue value:&uiTouch withObjCType:@encode(UITouch)];

        _touches[key] = touch;
    }
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event
{
    for(UITouch* uiTouch in touches)
    {
        CGPoint location        = [uiTouch locationInView:nil];
        CGPoint prevLocation    = [uiTouch previousLocationInView:nil];
        CGSize size             = uiTouch.view.bounds.size;

        simd::float2 pos        = simd::make_float2(location.x / size.width, location.y / size.height);

        NSValue* key = [NSValue value:&uiTouch withObjCType:@encode(UITouch)];

        AAPLTouch* touch    = _touches[key];
        touch.pos           = pos;
        touch.delta         = simd::make_float2(location.x, location.y) - simd::make_float2(prevLocation.x, prevLocation.y);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* uiTouch in touches)
    {
        NSValue* key = [NSValue value:&uiTouch withObjCType:@encode(UITouch)];

        [_touches removeObjectForKey:key];
    }
}

#else

// capture shift and ctrl
-(void)flagsChanged:(NSEvent*)event
{
    if(event.modifierFlags&NSEventModifierFlagShift)
        [_input.pressedKeys addObject:@(AAPLControlsFast)];
    else
        [_input.pressedKeys removeObject:@(AAPLControlsFast)];

    if (event.modifierFlags&NSEventModifierFlagControl)
        [_input.pressedKeys addObject:@(AAPLControlsSlow)];
    else
        [_input.pressedKeys removeObject:@(AAPLControlsSlow)];
}

// capture mouse and keyboard events
-(void)mouseExited:(NSEvent *)event         { }
-(void)rightMouseDown:(NSEvent *)event      { }
-(void)rightMouseUp:(NSEvent *)event        { }
-(void)mouseMoved:(NSEvent *)event          { }

-(void)mouseDown:(NSEvent *)event
{
    _input.mouseDown = true;

    _input.mouseCurrentPos = simd::make_float2(event.locationInWindow.x, event.locationInWindow.y);
    _input.mouseCurrentPos.x /= event.window.frame.size.width;
    _input.mouseCurrentPos.y /= event.window.frame.size.height;
    _input.mouseCurrentPos.y = 1.0f - _input.mouseCurrentPos.y;

    _input.mouseDownPos = _input.mouseCurrentPos;
}

-(void)mouseUp:(NSEvent *)event
{
    _input.mouseDown = false;
}

-(void)mouseDragged:(NSEvent *)event
{
    _input.mouseDeltaX = (float)event.deltaX;
    _input.mouseDeltaY = (float)event.deltaY;

    _input.mouseCurrentPos = simd::make_float2(event.locationInWindow.x, event.locationInWindow.y);
    _input.mouseCurrentPos.x /= event.window.frame.size.width;
    _input.mouseCurrentPos.y /= event.window.frame.size.height;
    _input.mouseCurrentPos.y = 1.0f - _input.mouseCurrentPos.y;
}

-(void)rightMouseDragged:(NSEvent *)event
{
    _input.mouseDeltaX = (float)event.deltaX;
    _input.mouseDeltaY = (float)event.deltaY;
}

-(void)keyUp:(NSEvent*)event
{
    [_input.pressedKeys removeObject:@(event.keyCode)];
}

-(void)keyDown:(NSEvent*)event
{
    if (!event.ARepeat)
    {
        [_input.pressedKeys addObject:@(event.keyCode)];
        [_input.justDownKeys addObject:@(event.keyCode)];
    }
}

#endif

- (void)viewDidLoad
{
    [super viewDidLoad];

    // -------------------
    // Initialize inputs
    // -------------------

    _input.initialize();
#if TARGET_OS_IPHONE
    _touches            = [NSMutableDictionary new];
#endif

    // -------------------
    // Initialize application views
    // -------------------

    _aaplView = (AAPLView*)self.view;
    _aaplView.device = MTLCreateSystemDefaultDevice();

    NSAssert(_aaplView.device, @"Metal is not supported on this device");

#if TARGET_OS_IPHONE
    NSAssert([_aaplView.device supportsFamily:MTLGPUFamilyApple4],
             @"Requires a device with an A11 or later");
#else
    NSAssert([_aaplView.device supportsFamily:MTLGPUFamilyMac2],
             @"Requires a mac which supports MTLGPUFamilyMac2" );
#endif

    _aaplView.delegate = self;

#if TARGET_OS_IPHONE
    _aaplView.backgroundColor       = UIColor.blackColor;
    _aaplView.multipleTouchEnabled  = YES;
#endif

#if TARGET_OS_IPHONE
    _settingsSwitch.on = NO; // Dont show settings at startup

    if(_settingsView != nil)
    {
        _settingsView.hidden = !_settingsSwitch.on;
    }
#endif

#if TARGET_OS_IPHONE
    _infoLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
#else
    _infoLabel.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
#endif

    // -------------------
    // Initialize Renderer
    // -------------------

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_aaplView];

    [_renderer resize:_aaplView.drawableSize];

#if SUPPORT_ON_SCREEN_SETTINGS
    [_renderer registerWidgets:_settingsController];

    [_settingsController reloadData];
#endif
}

#if TARGET_OS_IPHONE
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"settingsSegue"]) {
        _settingsController = segue.destinationViewController;
    }
}
#endif

#if TARGET_OS_IPHONE
- (void)viewWillAppear:(BOOL)animated
{
    static const double WideRatio = 1920.0/1080.0;

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect frame = _aaplView.frame;

    CGFloat WideScreenWidth = (screenBounds.size.height * WideRatio);
    frame.size.width = MIN(WideScreenWidth, screenBounds.size.width) ;
    frame.origin.x = (screenBounds.size.width - frame.size.width) / 2.0;
    _aaplView.frame = frame;

    if([UIScreen mainScreen].bounds.size.width < 850 )
    {
        CGSize drawableSize = { 1280,  720 };
        _aaplView.drawableSize = drawableSize;
    }
    else if([UIScreen mainScreen].bounds.size.width < 1150 )
    {
        CGSize drawableSize = { 1920,  1080};
        _aaplView.drawableSize = drawableSize;
    }
}
#endif  // TARGET_OS_IPHONE

- (void)drawInMTKView:(nonnull MTKView *)view
{
    // -------------------
    // Update Input state
    // -------------------

#if TARGET_OS_IPHONE
    [_touches enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop)
    {
        [self->_input.touches addObject:value];
    }];
#endif
    _input.update();

    // -------------------
    // -------------------

    if(_infoLabel.hidden != !_renderer.renderUI)
        _infoLabel.hidden = !_renderer.renderUI;

    // -------------------
    // Update and Render
    // -------------------

    [_renderer updateFrameState:_input];

    [_renderer drawInMTKView:view];

    _input.clear();

#if TARGET_OS_IPHONE
    [_touches enumerateKeysAndObjectsUsingBlock:^(id key, AAPLTouch* touch, BOOL* stop)
    {
        touch.delta = simd::make_float2(0.0f, 0.0f);
    }];
#endif

    // -------------------
    // Update UI
    // -------------------

#if TARGET_OS_IPHONE
    _infoLabel.text = _renderer.info;
#else
    _infoLabel.stringValue = _renderer.info;
#endif
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [_renderer resize:size];
}
@end
