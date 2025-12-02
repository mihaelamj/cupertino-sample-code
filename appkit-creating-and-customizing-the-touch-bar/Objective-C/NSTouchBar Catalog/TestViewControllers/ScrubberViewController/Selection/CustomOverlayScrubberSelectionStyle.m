/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSScrubberSelectionStyle to override the selection overlay.
*/

#import "CustomOverlayScrubberSelectionStyle.h"
#import "SelectionOverlayView.h"

@implementation CustomOverlayScrubberSelectionStyle

- (nullable __kindof NSScrubberSelectionView *)makeSelectionView
{
    SelectionOverlayView *selectionView = [[SelectionOverlayView alloc] init];
    return selectionView;
}

@end



