/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting details about a purchase.
*/

@import StoreKit;
#import "Section.h"
#import "AppConfiguration.h"
#import "PaymentTransactionDetails.h"

typedef NS_ENUM(NSInteger, PaymentTransactionDetailsSection) {
    PaymentTransactionDetailsSectionID = 0,
    PaymentTransactionDetailsSectionDate
};

NSString *const kBasicCellIdentifier = @"basic";
NSString *const kCustomCellIdentifier = @"custom";

@implementation PaymentTransactionDetails
#pragma mark - UITable​View​Data​Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = (self.data)[indexPath.section];
    
    if ([section.name isEqualToString:PCSPaymentTransactionDetailsOriginalTransaction]) {
        return [tableView dequeueReusableCellWithIdentifier:kCustomCellIdentifier forIndexPath:indexPath];
    } else {
        return [tableView dequeueReusableCellWithIdentifier:kBasicCellIdentifier forIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = (self.data)[indexPath.section];
    NSArray *transactions = section.elements;
    
    if ([section.name isEqualToString:PCSPaymentTransactionDetailsOriginalTransaction]) {
        NSDictionary *dictionary = transactions[indexPath.row];
        
        switch (indexPath.row) {
            case PaymentTransactionDetailsSectionID:
                cell.textLabel.text = PCSPaymentTransactionDetailsLabelsTransactionIdentifier;
                cell.detailTextLabel.text = dictionary[PCSPaymentTransactionDetailsLabelsTransactionIdentifier];
                break;
            case PaymentTransactionDetailsSectionDate:
                cell.textLabel.text = PCSPaymentTransactionDetailsLabelsTransactionDate;
                cell.detailTextLabel.text = dictionary[PCSPaymentTransactionDetailsLabelsTransactionDate];
        }
               
    } else {
        cell.textLabel.text = transactions.firstObject;
    }
}

@end

