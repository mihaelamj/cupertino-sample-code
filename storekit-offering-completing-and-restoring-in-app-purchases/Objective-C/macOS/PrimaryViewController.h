/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

@import Cocoa;

@interface PrimaryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
/// The data model that all BaseViewController subclasses use.
@property (strong) NSMutableArray *data;
/// The table view that all BaseViewController subclasses use.
@property (weak) IBOutlet NSTableView *tableView;
/// Reloads the UI with new products, invalid identifiers, and purchases.
-(void)reloadUIWithData:(NSMutableArray *)data;
@end
