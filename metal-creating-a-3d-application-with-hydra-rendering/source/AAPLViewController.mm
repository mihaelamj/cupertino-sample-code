/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller for the app.
*/

#import "AAPLViewController.h"
#import "AAPLCamera.h"
#import "AAPLRenderer.h"
#import <CoreImage/CoreImage.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

@implementation AAPLViewController
{
    MTKView* _view;
    AAPLRenderer* _renderer;
    CGPoint _mouseCoord;
}

/// Initialize the view, and load the renderer.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MTKView*)self.view;
    _view.layer.backgroundColor = NSColor.clearColor.CGColor;
    
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
    
    _view.delegate = _renderer;
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];
}

/// Upon opening the app, use the NSOpenPanel to allow the user to open a file.
- (void)viewDidAppear
{
    [super viewDidAppear];
    
    static bool firstTime = true;
    if (!firstTime)
    {
        return;
    }
    firstTime = false;
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeUSD, UTTypeUSDZ];
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK)
        {
            NSURL* url = panel.URLs[0];
            bool result = [url startAccessingSecurityScopedResource];
            if (result)
            {
                [self->_renderer setupScene:[url path]];
            }
        }
    }];
}

/// On a mouse button down, record the starting point for a drag.
- (void)mouseDown:(NSEvent*)event
{
    _mouseCoord = [self.view convertPoint:event.locationInWindow fromView:nil];
}

/// On a mouse button down event, records the starting point for a drag.
- (void)mouseDragged:(NSEvent*)event
{
    CGPoint newCoord = [self.view convertPoint:event.locationInWindow fromView:nil];
    
    double dX = newCoord.x - _mouseCoord.x;
    double dY = newCoord.y - _mouseCoord.y;
    
    if (event.modifierFlags & NSEventModifierFlagOption)
    {
        double magnification = event.modifierFlags & NSEventModifierFlagShift ? 2.0 : 0.5;
        [_renderer.viewCamera panByDelta:{-dX * magnification, -dY * magnification}];
    }
    else
    {
        [_renderer.viewCamera rotateByDelta:{-dX * 0.5, dY * 0.5}];
    }
    
    _mouseCoord = newCoord;
}

/// Handles the magnification gesture.
- (void)magnifyWithEvent:(NSEvent*)event
{
    double delta = -event.magnification;
    double magnification = event.modifierFlags & NSEventModifierFlagShift ? 160 : 16;
    
    [_renderer.viewCamera zoomByDelta:delta * magnification];
}

/// Adjusts the zoom of the camera if the user holds down a modifier key; otherwise, pans the camera.
- (void)scrollWheel:(NSEvent*)event
{
    if (event.modifierFlags & NSEventModifierFlagOption)
    {
        double delta = 5.0 * event.deltaY;
        
        [_renderer.viewCamera zoomByDelta:delta];
    }
    else
    {
        double dX = event.deltaX;
        double dY = event.deltaY;
        
        double magnification = event.modifierFlags & NSEventModifierFlagShift ? 5.0 : 1.0;
        
        [_renderer.viewCamera panByDelta:{-dX * magnification, dY * magnification}];
    }
}

@end
