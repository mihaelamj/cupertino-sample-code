/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for restoring all previously purchased non-consumable
 and auto-renewable subscriptions.
*/

#import "Settings.h"
#import "StoreObserver.h"

NSString *const kRestoreCellIdentifier = @"restore";

@implementation Settings
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell && [cell.reuseIdentifier isEqualToString:kRestoreCellIdentifier]) {
        [[StoreObserver sharedInstance] restore];
        [[NSNotificationCenter defaultCenter] postNotificationName:PCSRestoredWasCalledNotification object:nil];
    }
}

@end
