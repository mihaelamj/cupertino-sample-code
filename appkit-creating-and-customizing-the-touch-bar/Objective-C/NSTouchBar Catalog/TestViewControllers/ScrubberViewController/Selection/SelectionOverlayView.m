/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSView for the NSScrubber's overlay selection.
*/

#import "SelectionOverlayView.h"

@implementation SelectionOverlayView

- (void)drawRect:(NSRect)rect
{
    // Draw as an overlay: with a rounded rect, green.
    [[NSColor systemGreenColor] set];
    NSRect fillRect = NSInsetRect(rect, 4, 4);
    NSBezierPath *roundedRect = [NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:6 yRadius:6];
    [roundedRect fill];
}

@end



