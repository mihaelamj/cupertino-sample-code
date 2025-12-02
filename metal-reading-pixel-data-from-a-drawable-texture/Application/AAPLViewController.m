/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller.
*/
#import "AAPLViewController.h"
#import "AAPLRenderer.h"

#if TARGET_IOS
// Include the Photos framework to save images to the user's photo library.
#include <Photos/Photos.h>
#endif

#if TARGET_MACOS
#define PlatformLabel NSTextField
#define MakeRect      NSMakeRect
#else
#define PlatformLabel UILabel
#define MakeRect      CGRectMake
#endif

@implementation AAPLViewController
{
    MTKView         *_view;
    AAPLRenderer    *_renderer;

    CGPoint _readRegionBegin;

    __weak IBOutlet PlatformLabel *_infoLabel;
}

#pragma mark Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

#if TARGET_MACOS
    _infoLabel.stringValue = @"Click and optionally drag to read pixels.\n";
#else
    _infoLabel.text = @"Touch and optionally drag to read pixels.\n";
#endif
    _infoLabel.hidden = NO;

    // Set the view to use the default device.
    _view = (MTKView*)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    NSAssert(_view.device, @"Metal isn't supported on this device.");

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];

    NSAssert(_renderer, @"Renderer failed initialization.");

    // Initialize the renderer with the view size.
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    // Set to get callbacks from -[MTKView mtkView:drawableSizeWillChange:] and
    // -[MTKView and drawInMTKView:].
    _view.delegate = _renderer;
}

#pragma mark Region Selection and Reading Methods

CGRect validateSelectedRegion(CGPoint begin, CGPoint end, CGSize drawableSize)
{
    CGRect region;

    // Ensure that the end point is within the bounds of the drawable.
    if (end.x < 0)
    {
        end.x = 0;
    }
    else if (end.x > drawableSize.width)
    {
        end.x = drawableSize.width;
    }

    if (end.y < 0)
    {
        end.y = 0;
    }
    else if (end.y > drawableSize.height)
    {
        end.y = drawableSize.height;
    }

    // Ensure that the lower-right corner is always larger than the upper-left
    // corner.
    CGPoint lowerRight;
    lowerRight.x = begin.x > end.x ? begin.x : end.x;
    lowerRight.y = begin.y > end.y ? begin.y : end.y;

    CGPoint upperLeft;
    upperLeft.x = begin.x < end.x ? begin.x : end.x;
    upperLeft.y = begin.y < end.y ? begin.y : end.y;

    region.origin = upperLeft;
    region.size.width = lowerRight.x - upperLeft.x;
    region.size.height = lowerRight.y - upperLeft.y;

    // Ensure that the width and height are at least 1.
    if (region.size.width < 1)
    {
        region.size.width = 1;
    }

    if (region.size.height < 1)
    {
        region.size.height = 1;
    }

    return region;
}

-(void)beginReadRegion:(CGPoint)point
{
    _readRegionBegin = point;
    _renderer.outlineRect = CGRectMake(_readRegionBegin.x, _readRegionBegin.y, 1, 1);
    _renderer.drawOutline = YES;
}

-(void)moveReadRegion:(CGPoint)point
{
    _renderer.outlineRect = validateSelectedRegion(_readRegionBegin, point, _view.drawableSize);
}

-(void)endReadRegion:(CGPoint)point
{
    _renderer.drawOutline = NO;

    CGRect readRegion = validateSelectedRegion(_readRegionBegin, point, _view.drawableSize);

    // Perform read with the selected region.
    AAPLImage *image = [_renderer renderAndReadPixelsFromView:_view
                                                   withRegion:readRegion];

    // Output pixels to file or Photos library.
    {
        NSURL *location;

#if TARGET_MACOS
        // In macOS, store the read pixels in an image file and save it
        // to the user's desktop.
        location = [[NSFileManager defaultManager] homeDirectoryForCurrentUser];
        location = [location URLByAppendingPathComponent:@"Desktop"];
        location = [location URLByAppendingPathComponent:@"ReadPixelsImage.tga"];
        [image saveToTGAFileAtLocation:location];
        NSMutableString *labelText =
            [[NSMutableString alloc] initWithFormat:@"%d x %d pixels read at (%d, %d)\n"
                                                     "Saved file to Desktop/ReadPixelsImage.tga",
             (uint32_t)readRegion.size.width, (uint32_t)readRegion.size.height,
             (uint32_t)readRegion.origin.x, (uint32_t)readRegion.origin.y];

        _infoLabel.stringValue = labelText;
        _infoLabel.textColor = [NSColor whiteColor];

#else   // TARGET_IOS
        // In iOS, store the read pixels in an image file and save it to the
        // user's photo library.

        PHPhotoLibrary *photoLib = [PHPhotoLibrary sharedPhotoLibrary];

        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined)
        {
            // Request access to the user's photo library. Request access
            // only once and retrieve the user's authorization status afterward.

            dispatch_semaphore_t authorizeSemaphore = dispatch_semaphore_create(0);

            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
                {
                    dispatch_semaphore_signal(authorizeSemaphore); // Increment the semaphore.
                }];

            // Block the thread until the user completes the authorization
            // request and the semaphore value is greater than 0.
            dispatch_semaphore_wait(authorizeSemaphore, DISPATCH_TIME_FOREVER); // Wait until > 0.
        }

        // If the user declined access to their photo library, they must
        // go to their iOS device settings and manually change the authorization
        // status for this app.
        NSAssert([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized,
            @"You didn't authorize writing to the Photos library. Change status in Settings/ReadPixels.\n");
        location = [[NSFileManager defaultManager] temporaryDirectory];
        location = [location URLByAppendingPathComponent:@"ReadPixelsImage.tga"];
        [image saveToTGAFileAtLocation:location];

        NSError *error;

        [photoLib performChangesAndWait:^{ [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:location]; }
                                  error:&error];

        if (error)
        {
            NSAssert(0, @"Couldn't add image with to Photos library: %@", error);
        }
        else
        {
            NSMutableString *labelText =
                [[NSMutableString alloc] initWithFormat:@"%d x %d pixels read at (%d, %d)\n"
                                                         "Saved image to Photos library",
                 (uint32_t)readRegion.size.width, (uint32_t)readRegion.size.height,
                 (uint32_t)readRegion.origin.x, (uint32_t)readRegion.origin.y];

            _infoLabel.text = labelText;
            _infoLabel.textColor = [UIColor whiteColor];

            // Enable text wrapping to multiple lines.
            _infoLabel.numberOfLines = 0;
        }

#endif  // TARGET_IOS
    }
}

#pragma mark macOS UI Methods

#if TARGET_MACOS
- (void)viewDidAppear
{
    // Make the view controller the window's first responder so that it can
    // handle the Key events.
    [_view.window makeFirstResponder:self];
}

// Accept first responder so the view controller can respond to UI events.
- (BOOL)acceptsFirstResponder
{
    return YES;
}


- (void)mouseDown:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self beginReadRegion:topDownPixelPosition];
}


- (void)mouseDragged:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self moveReadRegion:topDownPixelPosition];
}

-(void)mouseUp:(NSEvent*)event
{
    CGPoint bottomUpPixelPosition = [_view convertPointToBacking:event.locationInWindow];
    CGPoint topDownPixelPosition = CGPointMake(bottomUpPixelPosition.x,
                                               _view.drawableSize.height - bottomUpPixelPosition.y);
    [self endReadRegion:topDownPixelPosition];
}


#else // if TARGET_IOS
#pragma mark iOS UI Methods

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];

    [self beginReadRegion:[self pointToBacking:[touch locationInView:_view]]];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];

    [self moveReadRegion:[self pointToBacking:[touch locationInView:_view]]];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];

    [self endReadRegion:[self pointToBacking:[touch locationInView:_view]]];
}

//------------------------------------------------------------------------------
// Convert raw touch point coordinates to drawable texture pixel coordinates.
// The view coordinates origin is in the upper-left corner of the view.
// Texture coordinates origin is also in the upper-left corner.

- (CGPoint)pointToBacking:(CGPoint)point
{
    CGFloat scale = _view.contentScaleFactor;

    CGPoint pixel;

    pixel.x = point.x * scale;
    pixel.y = point.y * scale;

    // Round the pixel values down to put them on a well-defined grid.
    pixel.x = (int64_t)pixel.x;
    pixel.y = (int64_t)pixel.y;

    // Add .5 to move to the center of the pixel.
    pixel.x += 0.5f;
    pixel.y += 0.5f;

    return pixel;
}
#endif  // TARGET_IOS

@end
