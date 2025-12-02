/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSView for the NSScrubber's background selection.
*/

#import "SelectionBackgroundView.h"

@implementation SelectionBackgroundView

- (void)drawRect:(NSRect)rect
{
    // Draw as a background: with a rounded rect, blue.
    [[NSColor systemBlueColor] set];
    NSBezierPath *ovalPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:6 yRadius:6];
    [ovalPath fill];
}

@end



