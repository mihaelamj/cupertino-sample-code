/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that retrieves product information from the App Store.
*/

@import StoreKit;
#import "AppConfiguration.h"

@interface StoreManager : NSObject
+ (StoreManager *)sharedInstance;

/// Indicates the cause of the product request failure.
@property (nonatomic, copy) NSString *message;

/// Provides the status of the product request.
@property (nonatomic) PCSProductRequestStatus status;

/// Keeps track of all valid products (these products are available for sale in the App Store) and all invalid product identifiers.
@property (strong) NSMutableArray *storeResponse;

/// Starts the product request with the specified identifiers.
-(void)startProductRequestWithIdentifiers:(NSArray *)identifiers;

/// - returns: The existing product's title matching the specified product identifier.
-(NSString *)titleMatchingIdentifier:(NSString *)identifier;

/// - returns: The existing product's title associated with the specified payment transaction.
-(NSString *)titleMatchingPaymentTransaction:(SKPaymentTransaction *)transaction;
@end

