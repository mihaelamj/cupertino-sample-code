/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

@import UIKit;
#import "IAPTableViewDataSource.h"

@interface BaseViewController : UITableViewController <IAPTableViewDataSource>
@property (strong) NSMutableArray *data;
@end
