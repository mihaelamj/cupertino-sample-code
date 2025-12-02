/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for the title bar accessory that contains the Set Background button.
*/

#import "TitleBarAccessoryViewController.h"
#import "BackgroundImagesViewController.h"

@implementation TitleBarAccessoryViewController

- (IBAction)presentPhotos:(id)sender
{
    if (self.openingViewController == nil)
    {
        _openingViewController =
            [self.storyboard instantiateControllerWithIdentifier: @"BackgroundImagesViewController"];
    }
    
    [self presentViewController:self.openingViewController
        asPopoverRelativeToRect:self.view.bounds
                         ofView:self.view
                  preferredEdge:NSRectEdgeMinY
                       behavior:NSPopoverBehaviorTransient];
}

@end
