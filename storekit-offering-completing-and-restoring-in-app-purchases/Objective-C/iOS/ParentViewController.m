/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for managing products available for sale, invalid
 product identifiers, and purchases.
*/

#import "Products.h"
#import "Purchases.h"
#import "Utilities.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "AppConfiguration.h"
#import "ParentViewController.h"

typedef NS_ENUM(NSInteger, ParentViewControllerSegment) {
    ParentViewControllerSegmentProducts = 0,
    ParentViewControllerSegmentPurchases
};

@interface ParentViewController ()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreButton;

@property (strong) Products *products;
@property (strong) Purchases *purchases;
@property (strong) Utilities *utility;
@end

@implementation ParentViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        _utility = [[Utilities alloc] init];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Disable or hide items.
    self.restoreButton.enabled = NO;
    
    self.products = [self instantiateProductsWithData:[NSMutableArray array]];
    self.purchases = [self instantiatePurchasesWithData:[NSMutableArray array]];
    
    // Registers for product request and purchase notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:PCSProductRequestNotification
                                               object:[StoreManager sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchaseNotification:)
                                                 name:PCSPurchaseNotification
                                               object:[StoreObserver sharedInstance]];
    // Fetch product information.
    [self fetchProductInformation];
}

#pragma mark - Instantiate View Controllers

-(Products *)instantiateProductsWithData:(NSMutableArray *)data {
    Products *controller = (Products *)[self.storyboard instantiateViewControllerWithIdentifier:PCSViewControllerIdentifiersProducts];
    controller.data = data;
    return controller;
}

-(Purchases *)instantiatePurchasesWithData:(NSMutableArray *)data {
    Purchases *controller = (Purchases *)[self.storyboard instantiateViewControllerWithIdentifier:PCSViewControllerIdentifiersPurchases];
    controller.data = data;
    return controller;
}

#pragma mark - Switching Between View Controllers

/// Adds a subview to the container.
-(void)addBaseViewController:(BaseViewController *)viewController {
    [self addChildViewController:viewController];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    viewController.view.frame = (self.containerView).bounds;
    [self.containerView addSubview:viewController.view];
    
    [NSLayoutConstraint activateConstraints:@[[viewController.view.topAnchor constraintEqualToAnchor: self.containerView.safeAreaLayoutGuide.topAnchor],
                                              [viewController.view.bottomAnchor constraintEqualToAnchor: self.containerView.safeAreaLayoutGuide.bottomAnchor],
                                              [viewController.view.leadingAnchor constraintEqualToAnchor: self.containerView.safeAreaLayoutGuide.leadingAnchor],
                                              [viewController.view.trailingAnchor constraintEqualToAnchor: self.containerView.safeAreaLayoutGuide.trailingAnchor]]];
    [viewController didMoveToParentViewController:self];
}

/// Removes a subview from the container.
-(void)removeBaseViewController:(BaseViewController *)ViewController {
    if (ViewController != nil) {
        [ViewController willMoveToParentViewController:nil];
        [ViewController.view removeFromSuperview];
        [ViewController removeFromParentViewController];
    }
}

/// Switches between the Products and Purchases view controllers.
-(void)switchToViewController:(ParentViewControllerSegment)segment {
    switch(segment){
        case ParentViewControllerSegmentProducts:
            [self removeBaseViewController:self.purchases];
            [self addBaseViewController:self.products];
            break;
        case ParentViewControllerSegmentPurchases:
            [self removeBaseViewController:self.products];
            [self addBaseViewController:self.purchases];
            break;
    }
}

#pragma mark - Fetch Product Information

/// Retrieves product information from the App Store.
-(void)fetchProductInformation {
    // Check whether the user has authorization to make purchases. Proceed if they do.
    if ([StoreObserver sharedInstance].isAuthorizedForPayments) {
        self.restoreButton.enabled = YES;
        NSArray *identifiers = self.utility.identifiers;
        
        if (identifiers != nil) {
            if (identifiers.count > 0) {
                Section *section = [[Section alloc] initWithName:PCSProductsInvalidIdentifiers elements:identifiers];
                
                // Refresh the UI with identifiers to query.
                [self switchToViewController:ParentViewControllerSegmentProducts];
                [self.products reloadWithData:[NSMutableArray arrayWithObject:section]];
                
                // Fetch the product information.
                [[StoreManager sharedInstance] startProductRequestWithIdentifiers:identifiers];
            } else {
                // Warn the user that the resource file doesn't contain anything.
                [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@.%@ %@", PCSProductIdsPlistName, PCSProductIdsPlistFileExtension, PCSMessagesEmptyResource]];
            }
        } else {
            // Warn the user that the resource file can't be found.
            [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@ %@.%@.", PCSMessagesResourceNotFound, PCSProductIdsPlistName, PCSProductIdsPlistFileExtension]];
        }
    } else {
        // Warn the user that they don’t have authorization to make purchases.
        [self alertWithTitle:PCSMessagesStatus message:[NSString stringWithFormat:@"%@", PCSMessagesCannotMakePayments]];
    }
}

#pragma mark - Display Alert

/// Creates and displays an alert.
-(void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [self.utility alertWithTitle:title message:message];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Restore All Appropriate Transactions

/// The system calls this when the user taps the Restore button.
- (IBAction)restore:(UIBarButtonItem *)sender {
    // Call StoreObserver to restore all restorable purchases.
    [[StoreObserver sharedInstance] restore];
}

#pragma mark - Handle Segmented Control Tap

/// The system calls this when the user taps any segmented control in the UI.
- (IBAction)segmentedControlSelectionDidChange:(UISegmentedControl *)sender {
    [self switchToViewController:sender.selectedSegmentIndex];
    
    switch(sender.selectedSegmentIndex){
        case ParentViewControllerSegmentProducts:
            [self fetchProductInformation];
            break;
        case ParentViewControllerSegmentPurchases:
            [self.purchases reloadWithData:self.utility.dataSourceForPurchasesUI];
            break;
    }
}

#pragma mark - Handle PCSProductRequest Notification

/// Updates the UI according to the product request notification result.
-(void)handleProductRequestNotification:(NSNotification *)notification {
    StoreManager *productRequestNotification = (StoreManager*)notification.object;
    PCSProductRequestStatus status = (PCSProductRequestStatus)productRequestNotification.status;
    
    if (status == PCSStoreResponse) {
        // Switch to the Products view controller.
        [self switchToViewController:ParentViewControllerSegmentProducts];
        [self.products reloadWithData:productRequestNotification.storeResponse];
        self.segmentedControl.selectedSegmentIndex = ParentViewControllerSegmentProducts;
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
        case PCSRestoreFailed: [self alertWithTitle:PCSMessagesPurchaseStatus message:purchasesNotification.message];
            break;
            // Switch to the Purchases view when receiving a successful restore notification.
        case PCSRestoreSucceeded: [self handleRestoredSucceededTransaction];
            break;
        default: break;
    }
}

#pragma mark - Handle Restored Transactions

/// Handles successful restored transactions. Switches to the Purchases view.
-(void)handleRestoredSucceededTransaction {
    self.utility.restoreWasCalled = YES;
    
    // Refresh the Purchases view with the restored purchases.
    [self switchToViewController:ParentViewControllerSegmentPurchases];
    [self.purchases reloadWithData:self.utility.dataSourceForPurchasesUI];
    self.segmentedControl.selectedSegmentIndex = ParentViewControllerSegmentPurchases;
}

#pragma mark - Memory Management

- (void)dealloc {
    // Unregister for StoreManager's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSProductRequestNotification object:[StoreManager sharedInstance]];
    
    // Unregister for StoreObserver's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSPurchaseNotification object:[StoreObserver sharedInstance]];
}

@end
