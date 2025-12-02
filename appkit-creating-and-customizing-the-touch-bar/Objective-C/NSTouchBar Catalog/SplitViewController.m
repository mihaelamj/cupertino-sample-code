/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main split-view controller for this sample (primary = table of tests, detail = each view controller test).
*/

#import "SplitViewController.h"

@implementation SplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.splitView.autosaveName = @"SplitViewAutosSave";
    
    self.minimumThicknessForInlineSidebars = 10.0;
}

@end
