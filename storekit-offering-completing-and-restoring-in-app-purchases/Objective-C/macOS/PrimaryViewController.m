/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

#import "PrimaryViewController.h"

@implementation PrimaryViewController
#pragma mark - Reload UI

/// Reloads the UI with new products, invalid identifiers, and purchases.
-(void)reloadUIWithData:(NSMutableArray *)data {
    self.data = data;
    [self.tableView reloadData];
}

#pragma mark - NSTable​View​Data​Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.data.count;
}

@end
