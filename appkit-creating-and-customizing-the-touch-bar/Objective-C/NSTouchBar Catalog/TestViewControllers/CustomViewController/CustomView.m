/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSView responsible for showing low-level touch events.
*/

#import "CustomView.h"

@interface CustomView ()

@property NSInteger selection;
@property NSInteger oldSelection;
@property id trackingTouchIdentity;

@end


#pragma mark - CustomView

@implementation CustomView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)touchesBeganWithEvent:(NSEvent *)event
{
    // You're already tracking a touch, so this must be a new touch.
    // What should you do? Cancel or ignore.
    //
    if (self.trackingTouchIdentity == nil)
    {
        NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseBegan inView:self];
        // Note: Touches may contain zero, one, or more touches.
        // What to do if there is more than one touch?
        // In this example, randomly pick a touch to track and ignore the other one.
        
        NSTouch *touch = touches.anyObject;
        if (touch != nil)
        {
            if (touch.type == NSTouchTypeDirect)
            {
                _trackingTouchIdentity = touch.identity;
                
                // Remember the selection value at the start of tracking in case you need to cancel.
                _oldSelection = self.selection;
                
                NSPoint location = [touch locationInView:self];
                self.trackingLocationString = [NSString stringWithFormat:NSLocalizedString(@"Began At", @""), location.x];
            }
        }
    }
    
    [super touchesBeganWithEvent:event];
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    if (self.trackingTouchIdentity)
    {
        for (NSTouch *touch in [event touchesMatchingPhase:NSTouchPhaseMoved inView:self])
        {
            if (touch.type == NSTouchTypeDirect && [_trackingTouchIdentity isEqual:touch.identity])
            {
                NSPoint location = [touch locationInView:self];
                self.trackingLocationString = [NSString stringWithFormat:NSLocalizedString(@"Moved At", @""), location.x];
                
                break;
            }
        }
    }
    
    [super touchesMovedWithEvent:event];
}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
    if (self.trackingTouchIdentity)
    {
        for (NSTouch *touch in [event touchesMatchingPhase:NSTouchPhaseEnded inView:self])
        {
            if (touch.type == NSTouchTypeDirect && [_trackingTouchIdentity isEqual:touch.identity])
            {
                // Finshed tracking successfully.
                _trackingTouchIdentity = nil;
                
                NSPoint location = [touch locationInView:self];
                self.trackingLocationString = [NSString stringWithFormat:NSLocalizedString(@"Ended At", @""), location.x];
                break;
            }
        }
    }

    [super touchesEndedWithEvent:event];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event
{    
    if (self.trackingTouchIdentity)
    {
        for (NSTouch *touch in [event touchesMatchingPhase:NSTouchPhaseMoved inView:self])
        {
            if (touch.type == NSTouchTypeDirect && [self.trackingTouchIdentity isEqual:touch.identity])
            {
                // CANCEL
                // This can happen for a number of reasons.
                // # A gesture recognizer started recognizing a touch.
                // # The underlying touch context changed (the user pressed Command-Tab while interacting with this view).
                // # The hardware canceled the touch.
                // Whatever the reason, put things back the way they were. In this example, reset the selection.
                //
                _trackingTouchIdentity = nil;
                
                self.selection = self.oldSelection;
                
                NSPoint location = [touch locationInView:self];
                self.trackingLocationString = [NSString stringWithFormat:NSLocalizedString(@"Canceled At", @""), location.x];
            }
        }
    }
    
    [super touchesCancelledWithEvent:event];
}

@end
