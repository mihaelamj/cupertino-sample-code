/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that retrieves product information from the App Store.
*/
#import "Section.h"
#import "StoreManager.h"

@interface StoreManager()<SKRequestDelegate, SKProductsRequestDelegate>
/// Keeps track of all valid products. These products are available for sale in the App Store.
@property (strong) NSMutableArray *availableProducts;

/// Keeps track of all invalid product identifiers.
@property (strong) NSMutableArray *invalidProductIdentifiers;

/// Keeps a strong reference to the product request.
@property (strong) SKProductsRequest *productRequest;
@end

@implementation StoreManager

+ (StoreManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static StoreManager * storeManagerSharedInstance;
    
    dispatch_once(&onceToken, ^{
        storeManagerSharedInstance = [[StoreManager alloc] init];
    });
    return storeManagerSharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self != nil) {
        _availableProducts = [[NSMutableArray alloc] initWithCapacity:0];
        _invalidProductIdentifiers = [[NSMutableArray alloc] initWithCapacity:0];
        _storeResponse = [[NSMutableArray alloc] initWithCapacity:0];
        _status = PCSProductRequestStatusNone;
    }
    return self;
}

#pragma mark - Request Information

/// Starts the product request with the specified identifiers.
-(void)startProductRequestWithIdentifiers:(NSArray *)identifiers {
    [self fetchProductsMatchingIdentifiers:identifiers];
}

/// Fetches information about your products from the App Store.
-(void)fetchProductsMatchingIdentifiers:(NSArray *)identifiers {
    // Create a set for the product identifiers.
    NSSet *productIdentifiers = [NSSet setWithArray:identifiers];
    
    // Initialize the product request with the above identifiers.
    self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productRequest.delegate = self;
    
    // Send the request to the App Store.
    [self.productRequest start];
}

#pragma mark - SKProductsRequestDelegate

/// The system uses this to get the App Store's response to your request and notify your observer.
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (self.storeResponse.count > 0) {
        [self.storeResponse removeAllObjects];
    }
    
    // Contains products with identifiers that the App Store recognizes. As such, they are available for purchase.
    if ((response.products).count > 0) {
        self.availableProducts = [NSMutableArray arrayWithArray:response.products];
        Section *section = [[Section alloc] initWithName:PCSProductsAvailableProducts elements:response.products];
        [self.storeResponse addObject:section];
    }
    
    // invalidProductIdentifiers contains all product identifiers that the App Store doesn’t recognize.
    if ((response.invalidProductIdentifiers).count > 0) {
        self.invalidProductIdentifiers = [NSMutableArray arrayWithArray:response.invalidProductIdentifiers];
        Section *section = [[Section alloc] initWithName:PCSProductsInvalidIdentifiers elements:response.invalidProductIdentifiers];
        [self.storeResponse addObject:section];
    }
    
    if (self.storeResponse.count > 0) {
        self.status = PCSStoreResponse;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PCSProductRequestNotification object:self];
        });
    }
}

#pragma mark - SKRequestDelegate

/// The system calls this when the product request fails.
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.status = PCSRequestFailed;
    self.message = error.localizedDescription;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PCSProductRequestNotification object:self];
    });
}

#pragma mark - Helper Methods

/// - returns: The existing product's title matching the specified product identifier.
-(NSString *)titleMatchingIdentifier:(NSString *)identifier {
    NSString *title = nil;
    
    // Search availableProducts for a product with a productIdentifier property that matches identifier, and return its localized title.
    for (SKProduct *product in self.availableProducts) {
        if ([product.productIdentifier isEqualToString:identifier]) {
            title = product.localizedTitle;
        }
    }
    return title;
}

/// - returns: The existing product's title associated with the specified payment transaction.
-(NSString *)titleMatchingPaymentTransaction:(SKPaymentTransaction *) transaction {
    NSString *title = [self titleMatchingIdentifier:transaction.payment.productIdentifier];
    return (title != nil) ? title : transaction.payment.productIdentifier;
}

@end

