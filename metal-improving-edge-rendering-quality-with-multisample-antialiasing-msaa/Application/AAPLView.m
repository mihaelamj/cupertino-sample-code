/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom view class implementation that receives keyboard events.
*/
#import "AAPLView.h"

#if TARGET_MACOS

/// The custom view class that allows the app to handle keyboard events.
@implementation AAPLView

/// Returns true so that the event messages get sent to this view class.
- (BOOL)acceptsFirstResponder
{
    return YES;
}

/// Handles the key down event and sends it to the view controller delegate.
- (void)keyDown:(NSEvent *)event
{
    NSView* view = (NSView*)self.delegate;
    if (view)
    {
        [view keyDown:event];
    }
    else
    {
        [super keyDown:event];
    }
}

@end

#endif
