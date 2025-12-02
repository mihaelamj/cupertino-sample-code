/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that provides purchase data and creates an alert.
*/

@import StoreKit;
#import "Utilities.h"
#import "StoreObserver.h"
#import "AppConfiguration.h"

@implementation Utilities

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _restoreWasCalled = NO;
    }
    return self;
}

/// - returns: An array with the product identifiers to query.
-(NSArray *)identifiers {
    NSURL *url = [[NSBundle mainBundle] URLForResource:PCSProductIdsPlistName withExtension:PCSProductIdsPlistFileExtension];
    return [NSArray arrayWithContentsOfURL:url];
}

/// - returns: An array for populating the Purchases view.
-(NSMutableArray *)dataSourceForPurchasesUI {
    NSMutableArray *dataSource = [[NSMutableArray alloc] initWithCapacity:0];
    NSArray *purchased = [[StoreObserver sharedInstance].productsPurchased copy];
    NSArray *restored = [[StoreObserver sharedInstance].productsRestored copy];
    
    if (self.restoreWasCalled && (restored.count > 0) && (purchased.count > 0)) {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[Section alloc] initWithName:PCSPurchasesPurchased elements:purchased],
                      [[Section alloc] initWithName:PCSPurchasesRestored elements:restored], nil];
        
    } else if (self.restoreWasCalled && (restored.count > 0)) {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[Section alloc] initWithName:PCSPurchasesRestored elements:restored], nil];
    } else if (purchased.count > 0) {
        dataSource = [[NSMutableArray alloc] initWithObjects:[[Section alloc] initWithName:PCSPurchasesPurchased elements:purchased], nil];
    }
    
    /*
     Display restored products only when the user taps the Restore button (iOS), Store > Restore (macOS), or Restore all restorable purchases (tvOS)
     and there are restored products.
    */
    self.restoreWasCalled = NO;
    return dataSource;
}

#pragma mark - Create Alert

#if TARGET_OS_IOS || TARGET_OS_TV
/// - returns: An alert with a given title and message.
-(UIAlertController *)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:PCSMessagesOk style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    return alert;
}
#endif

#pragma mark - Parse Section of Data

/// - returns: A Section object matching the specified name in the data array.
-(Section *)parse:(NSArray *)data forName:(NSString *)name {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    return (Section *)([data filteredArrayUsingPredicate:predicate].firstObject);
}

@end

