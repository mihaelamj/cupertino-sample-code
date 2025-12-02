/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSScrubberSelectionStyle to override the selection background.
*/

#import "CustomBackgroundScrubberSelectionStyle.h"
#import "SelectionBackgroundView.h"

@implementation CustomBackgroundScrubberSelectionStyle

- (nullable __kindof NSScrubberSelectionView *)makeSelectionView
{
    SelectionBackgroundView *selectionView = [[SelectionBackgroundView alloc] init];
    return selectionView;
}

@end



