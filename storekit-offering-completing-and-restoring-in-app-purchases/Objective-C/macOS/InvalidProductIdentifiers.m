/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting a list of invalid product identifiers.
*/

#import "InvalidProductIdentifiers.h"

@implementation InvalidProductIdentifiers
#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (cell != nil) {
        cell.textField.stringValue = self.data[row];
        return cell;
    }
    return nil;
}
@end
