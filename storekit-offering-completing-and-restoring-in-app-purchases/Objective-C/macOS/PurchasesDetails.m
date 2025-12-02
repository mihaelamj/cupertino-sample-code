/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting details about a purchase.
*/

@import StoreKit;
#import "StoreManager.h"
#import "PurchasesDetails.h"
#import "NSDateFormatter+DateFormatter.h"

@interface PurchasesDetails ()
@property (weak) IBOutlet NSStackView *stackView;
@property (weak) IBOutlet NSTextField *productID;
@property (weak) IBOutlet NSTextField *transactionID;
@property (weak) IBOutlet NSTextField *transactionDate;

@property (weak) IBOutlet NSBox *originalTransaction;
@property (weak) IBOutlet NSTextField *originalTransactionID;
@property (weak) IBOutlet NSTextField *originalTransactionDate;
@end

@implementation PurchasesDetails
#pragma mark - View Life Cycle

- (void)viewDidAppear {
    [super viewDidAppear];
    
    [self hideBox:self.originalTransaction forStatus:YES];
    [self reloadTableAndSelectFirstRowIfNecessary];
}

#pragma mark - Update UI

/// Hides an NSBox object if the specified status is true. Shows it, otherwise.
-(void)hideBox:(NSBox *)box forStatus:(BOOL)status {
    if (self.viewLoaded) {
        box.hidden = status;
        [self.view layoutSubtreeIfNeeded];
    }
}

/// Reloads the UI with new products, invalid identifiers, and purchases.
-(void)reloadUIWithData:(NSMutableArray *)data {
    self.data = data;
    [self.tableView reloadData];
    [self reloadTableAndSelectFirstRowIfNecessary];
}

/// Reloads the table view and programmatically selects a purchase.
-(void)reloadTableAndSelectFirstRowIfNecessary {
    // Select the first purchase and display its information if no row is currently in a selected state. Display the current selection, otherwise.
    NSIndexSet *selection = (self.tableView.selectedRowIndexes.count == 0) ? [NSIndexSet indexSetWithIndex:0] : self.tableView.selectedRowIndexes;
    
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:selection byExtendingSelection:NO];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SKPaymentTransaction *transaction = (SKPaymentTransaction *)self.data[row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (cell != nil) {
        // Display the product's title associated with the payment's product identifier.
        cell.textField.stringValue = [[StoreManager sharedInstance] titleMatchingPaymentTransaction:transaction];
        return cell;
    }
    return nil;
}

/// Displays information about the selected purchase or a restored one.
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = (self.tableView).selectedRow;
    NSDateFormatter *dateFormatter = [NSDateFormatter longStyle];
    
    [self hideBox:self.originalTransaction forStatus:YES];
    
    if (selectedRow >= 0 && (self.data.count > 0)) {
        SKPaymentTransaction *transaction = (SKPaymentTransaction *)self.data[selectedRow];
        
        self.productID.stringValue = transaction.payment.productIdentifier;
        self.transactionID.stringValue = transaction.transactionIdentifier;
        self.transactionDate.stringValue = [dateFormatter stringFromDate:transaction.transactionDate];
                
        // Display restored transactions if they exist.
        if (transaction.originalTransaction != nil) {
            [self hideBox:self.originalTransaction forStatus:NO];
            
            self.originalTransactionID.stringValue = transaction.originalTransaction.transactionIdentifier;
            self.originalTransactionDate.stringValue = [dateFormatter stringFromDate:transaction.originalTransaction.transactionDate];
        }
    }
}

@end

