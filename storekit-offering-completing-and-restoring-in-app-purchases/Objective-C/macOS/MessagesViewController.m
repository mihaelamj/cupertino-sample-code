/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for showing error and status messages.
*/

#import "MessagesViewController.h"

@interface MessagesViewController ()
@property (weak) IBOutlet NSTextField *messageLabel;
@end

@implementation MessagesViewController
#pragma mark - View Life Cycle

-(void)viewDidAppear {
    [super viewDidAppear];
    if (self.message) {
        self.messageLabel.stringValue = self.message;
    }
}
@end
