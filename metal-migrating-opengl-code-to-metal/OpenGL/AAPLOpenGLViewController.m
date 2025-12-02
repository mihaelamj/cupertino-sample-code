/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller and cross-platform view that displays OpenGL content.
*/
#import "AAPLOpenGLViewController.h"
#import "AAPLOpenGLRenderer.h"


#ifdef TARGET_MACOS
#import <AppKit/AppKit.h>
#define PlatformGLContext NSOpenGLContext
#else // if!(TARGET_IOS || TARGET_TVOS)
#import <UIKit/UIKit.h>
#define PlatformGLContext EAGLContext
#endif // !(TARGET_IOS || TARGET_TVOS)

@implementation AAPLOpenGLView

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}
#endif

@end

@implementation AAPLOpenGLViewController
{
    AAPLOpenGLView *_view;
    AAPLOpenGLRenderer *_openGLRenderer;
    PlatformGLContext *_context;
    GLuint _defaultFBOName;

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
    CADisplayLink *_displayLink;
#else
    CVDisplayLinkRef _displayLink;
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (AAPLOpenGLView *)self.view;

    [self prepareView];

    [self makeCurrentContext];

    _openGLRenderer = [[AAPLOpenGLRenderer alloc] initWithDefaultFBOName:_defaultFBOName];

    if(!_openGLRenderer)
    {
        NSLog(@"OpenGL renderer failed initialization.");
        return;
    }

    [_openGLRenderer resize:self.drawableSize];
}

#if TARGET_MACOS

- (CGSize) drawableSize
{
    CGSize viewSizePoints = _view.bounds.size;

    CGSize viewSizePixels = [_view convertSizeToBacking:viewSizePoints];

    return viewSizePixels;
}

- (void)makeCurrentContext
{
    [_context makeCurrentContext];
}

static CVReturn OpenGLDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                         const CVTimeStamp* now,
                                         const CVTimeStamp* outputTime,
                                         CVOptionFlags flagsIn,
                                         CVOptionFlags* flagsOut,
                                         void* displayLinkContext)
{
    AAPLOpenGLViewController *viewController = (__bridge AAPLOpenGLViewController*)displayLinkContext;

    [viewController draw];
    return YES;
}

- (void)draw
{
    CGLLockContext(_context.CGLContextObj);

    [_context makeCurrentContext];

    [_openGLRenderer draw];

    CGLFlushDrawable(_context.CGLContextObj);
    CGLUnlockContext(_context.CGLContextObj);
}

- (void)prepareView
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    NSAssert(pixelFormat, @"No OpenGL pixel format.");

    _context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

    CGLLockContext(_context.CGLContextObj);

    [_context makeCurrentContext];

    CGLUnlockContext(_context.CGLContextObj);

    glEnable(GL_FRAMEBUFFER_SRGB);
    _view.pixelFormat = pixelFormat;
    _view.openGLContext = _context;
    _view.wantsBestResolutionOpenGLSurface = YES;

    // The default framebuffer object (FBO) is 0 on macOS, because it uses a traditional OpenGL
    // pixel format model.
    _defaultFBOName = 0;

    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);

    // Set the renderer output callback function.
    CVDisplayLinkSetOutputCallback(_displayLink, &OpenGLDisplayLinkCallback, (__bridge void*)self);

    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, _context.CGLContextObj, pixelFormat.CGLPixelFormatObj);
}

- (void)viewDidLayout
{
    CGLLockContext(_context.CGLContextObj);

    NSSize viewSizePoints = _view.bounds.size;

    NSSize viewSizePixels = [_view convertSizeToBacking:viewSizePoints];

    [self makeCurrentContext];

    [_openGLRenderer resize:viewSizePixels];

    CGLUnlockContext(_context.CGLContextObj);

    if(!CVDisplayLinkIsRunning(_displayLink))
    {
        CVDisplayLinkStart(_displayLink);
    }
}

- (void) viewWillDisappear
{
    CVDisplayLinkStop(_displayLink);
}

- (void)dealloc
{
    CVDisplayLinkStop(_displayLink);

    CVDisplayLinkRelease(_displayLink);
}

#else

- (void)draw:(id)sender
{
    [EAGLContext setCurrentContext:_context];
    [_openGLRenderer draw];

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)makeCurrentContext
{
    [EAGLContext setCurrentContext:_context];
}

- (void)prepareView
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.view.layer;

    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @NO,
                                     kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatSRGBA8 };
    eaglLayer.opaque = YES;

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!_context || ![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Could not create an OpenGL ES context.");
        return;
    }

    [self makeCurrentContext];

    self.view.contentScaleFactor = [UIScreen mainScreen].nativeScale;

    // In iOS & tvOS, you must create an FBO and attach a drawable texture allocated by
    // Core Animation to use as the default FBO for a view.
    glGenFramebuffers(1, &_defaultFBOName);
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);

    glGenRenderbuffers(1, &_colorRenderbuffer);

    glGenRenderbuffers(1, &_depthRenderbuffer);

    [self resizeDrawable];

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);

    // Create the display link so you render at 60 frames per second (FPS).
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(draw:)];

    _displayLink.preferredFramesPerSecond = 60;

    // Set the display link to run on the default run loop (and the main thread).
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (CGSize)drawableSize
{
    GLint backingWidth, backingHeight;
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    CGSize drawableSize = {backingWidth, backingHeight};
    return drawableSize;
}

- (void)resizeDrawable
{
    [self makeCurrentContext];

    // First, ensure that you have a render buffer.
    assert(_colorRenderbuffer != 0);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)_view.layer];

    CGSize drawableSize = self.drawableSize;

    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, drawableSize.width, drawableSize.height);

    GetGLError();

    [_openGLRenderer resize:self.drawableSize];
}

- (void)viewDidLayoutSubviews
{
    [self resizeDrawable];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self resizeDrawable];
}

#endif
@end
