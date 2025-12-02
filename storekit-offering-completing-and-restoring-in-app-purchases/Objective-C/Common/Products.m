/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting products available for sale
 in the App Store and invalid product identifiers.
*/

@import StoreKit;
#import "Section.h"
#import "Products.h"
#import "StoreObserver.h"
#import "AppConfiguration.h"
#import "SKProduct+SKProductAdditions.h"

NSString *const kAvailableProductCellIdentifier = @"available";
NSString *const kInvalidIdentifierCellIdentifier = @"invalid";

@implementation Products
#pragma mark - UITable​View​Data​Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = (self.data)[indexPath.section];
    
    if ([section.name isEqualToString:PCSProductsAvailableProducts]) {
        return [tableView dequeueReusableCellWithIdentifier:kAvailableProductCellIdentifier forIndexPath:indexPath];
    } else {
        return [tableView dequeueReusableCellWithIdentifier:kInvalidIdentifierCellIdentifier forIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = (self.data)[indexPath.section];
    NSArray *content = section.elements;
    
    // If there are available products, show them.
    if ([section.name isEqualToString:PCSProductsAvailableProducts]) {
        SKProduct *product = content[indexPath.row];
        
        // Show the localized title of the product.
        cell.textLabel.text = product.localizedTitle;
        
        // Show the product's price in the locale and currency that the App Store returns.
        cell.detailTextLabel.text = product.regularPrice;
    } else if ([section.name isEqualToString:PCSProductsInvalidIdentifiers]) {
        // If there are invalid product identifiers, show them.
        cell.textLabel.text = content[indexPath.row];
    }
}

/// Starts a purchase when the user taps an available product row.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Section *section = (self.data)[indexPath.section];
    
    // The user can only purchase available products.
    if([section.name isEqualToString:PCSProductsAvailableProducts]) {
        NSArray *content = section.elements;
        SKProduct *product = (SKProduct *)content[indexPath.row];
        
        // Attempt to purchase the tapped product.
        [[StoreObserver sharedInstance] buy:product];
    }
}

@end

