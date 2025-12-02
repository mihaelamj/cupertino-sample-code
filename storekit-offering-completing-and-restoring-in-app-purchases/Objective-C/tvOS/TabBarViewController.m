/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The tab bar view controller for managing products available for sale, invalid
 product identifiers, purchases, and app settings.
*/

@import StoreKit;
#import "Utilities.h"
#import "Products.h"
#import "Purchases.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "AppConfiguration.h"
#import "TabBarViewController.h"

typedef NS_ENUM(NSInteger, TabBarViewControllerItems) {
    TabBarViewControllerProducts = 0,
    TabBarViewControllerPurchases,
    TabBarViewControllerSettings
};

@interface TabBarViewController () <UITabBarControllerDelegate>
@property (strong) Utilities *utility;
@property BOOL restoreWasCalled;

@property (strong) Products *products;
@property (strong) Purchases *purchases;
@end

@implementation TabBarViewController
#pragma mark - Initializers

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _utility = [[Utilities alloc] init];
        _restoreWasCalled = NO;
    }
    return self;
}

#pragma mark - Instantiate View Controllers

-(Products *)instantiateProducts {
    UINavigationController *navigation = (UINavigationController *)self.viewControllers[TabBarViewControllerProducts];
    if ([navigation.topViewController isKindOfClass:[Products class]]) {
        Products *controller = (Products *)navigation.topViewController;
        return controller;
    }
    return nil;
}

-(Purchases *)instantiatePurchases {
    UINavigationController *navigation = (UINavigationController *)self.viewControllers[TabBarViewControllerPurchases];
    if ([navigation.topViewController isKindOfClass:[Purchases class]]) {
        Purchases *controller = (Purchases *)navigation.topViewController;
        return controller;
    }
    return nil;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    
    self.products = [self instantiateProducts];
    self.purchases = [self instantiatePurchases];
    
    // Registers for product request, purchase, and restore notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:PCSProductRequestNotification
                                               object:[StoreManager sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchaseNotification:)
                                                 name:PCSPurchaseNotification
                                               object:[StoreObserver sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRestoreNotification:)
                                                 name:PCSRestoredWasCalledNotification
                                               object:nil];
}

#pragma mark - Fetch Product Information

/// Retrieves product information from the App Store.
-(void)fetchProductInformation {
    // Check whether the user has authorization to make purchases. Proceed if they do.
    if ([StoreObserver sharedInstance].isAuthorizedForPayments) {
        NSArray *identifiers = self.utility.identifiers;
        
        if (identifiers != nil) {
            if (identifiers.count > 0) {
                // Refresh the UI with identifiers to query.
                Section *section = [[Section alloc] initWithName:PCSProductsInvalidIdentifiers elements:identifiers];
                [self.products reloadWithData:@[section]];
                
                // Fetch the product information.
                [[StoreManager sharedInstance] startProductRequestWithIdentifiers:identifiers];
            } else {
                // Warn the user that the resource file doesn’t contain anything.
                [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@.%@ %@", PCSProductIdsPlistName, PCSProductIdsPlistFileExtension, PCSMessagesEmptyResource]];
            }
        } else {
            // Warn the user that the resource file can’t be found.
            [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@ %@.%@.", PCSMessagesResourceNotFound, PCSProductIdsPlistName, PCSProductIdsPlistFileExtension]];
        }
    } else {
        // Warn the user that they don’t have authorization to make purchases.
        [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@", PCSMessagesCannotMakePayments]];
    }
}

#pragma mark - Handle PCSProductRequest Notification

/// Updates the UI according to the product request notification result.
-(void)handleProductRequestNotification:(NSNotification *)notification {
    StoreManager *productRequestNotification = (StoreManager*)notification.object;
    PCSProductRequestStatus status = (PCSProductRequestStatus)productRequestNotification.status;
    
    if (status == PCSStoreResponse) {
        [self.products reloadWithData:productRequestNotification.storeResponse];
    } else if (status == PCSRequestFailed) {
        [self alertWithTitle:PCSMessagesProductRequestStatus message:productRequestNotification.message];
    }
}

#pragma mark - Handle PCSPurchase Notification

/// Updates the UI according to the purchase request notification result.
-(void)handlePurchaseNotification:(NSNotification *)notification {
    StoreObserver *purchasesNotification = (StoreObserver *)notification.object;
    PCSPurchaseStatus status = (PCSPurchaseStatus)purchasesNotification.status;
    
    switch (status) {
        case PCSNoRestorablePurchases:
        case PCSPurchaseFailed:
        case PCSRestoreFailed:
            [self alertWithTitle:PCSMessagesPurchaseStatus message:purchasesNotification.message];
            break;
        // Switch to the Purchases view when receiving a successful restore notification.
        case PCSRestoreSucceeded: [self handleRestoredSucceededTransaction];
            break;
        default: break;
    }
}

#pragma mark - Handle Restored Transactions

/// Handles successful restored transactions. Switches to the Purchases tab.
-(void)handleRestoredSucceededTransaction {
    self.utility.restoreWasCalled = self.restoreWasCalled;
    [self.purchases reloadWithData:self.utility.dataSourceForPurchasesUI];
    self.selectedIndex = TabBarViewControllerPurchases;
}

#pragma mark - Handle PCSRestoredWasCalled Notification

-(void)handleRestoreNotification:(NSNotification *)notification {
    self.restoreWasCalled = YES;
}

#pragma mark - Managing Tab Bar Selections

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return [StoreObserver sharedInstance].isAuthorizedForPayments;
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    
    if (index == TabBarViewControllerProducts) {
        self.restoreWasCalled = NO;
        [self fetchProductInformation];
    } else if (index == TabBarViewControllerPurchases) {
        UINavigationController *navigation = (UINavigationController *)viewController;
        
        if ([navigation.topViewController isKindOfClass:[Purchases class]]) {
            Purchases *controller = (Purchases *)navigation.topViewController;
            self.utility.restoreWasCalled = self.restoreWasCalled;
            [controller reloadWithData:self.utility.dataSourceForPurchasesUI];
        }
    } else if (index == TabBarViewControllerSettings) {
        self.restoreWasCalled = NO;
    }
}

#pragma mark - Display Alert

/// Creates and displays an alert.
-(void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [self.utility alertWithTitle:title message:message];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Memory Management

- (void)dealloc {
    // Unregister for StoreManager's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSProductRequestNotification object:[StoreManager sharedInstance]];
    
    // Unregister for StoreObserver's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSPurchaseNotification object:[StoreObserver sharedInstance]];
    
    // Unregister for Settings' notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSRestoredWasCalledNotification object:nil];
}

@end

