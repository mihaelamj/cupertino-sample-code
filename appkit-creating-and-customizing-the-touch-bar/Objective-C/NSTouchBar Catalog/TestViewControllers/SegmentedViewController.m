/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing segmented controls in an NSTouchBar instance.
*/

#import "SegmentedViewController.h"

@implementation SegmentedViewController

// Note: This particular view controller doesn't allow customizing of its NSTouchBar instance.

- (IBAction)segmentAction:(id)sender
{
    NSSegmentedControl *segControl = (NSSegmentedControl *)sender;
    NSLog(@"segment selection = %ld", segControl.selectedSegment);
}

@end
