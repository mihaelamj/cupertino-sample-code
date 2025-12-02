/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for managing products available for sale, invalid product
 identifiers, purchases, and messages.
*/

@import StoreKit;
#import "Utilities.h"
#import "StoreManager.h"
#import "StoreObserver.h"
#import "PurchasesDetails.h"
#import "AppConfiguration.h"
#import "AvailableProducts.h"
#import "MainViewController.h"
#import "MessagesViewController.h"
#import "InvalidProductIdentifiers.h"

NSString *const kSectionName = @"name";

@interface MainViewController ()
@property (weak) IBOutlet NSStackView *stackView;
@property (weak) IBOutlet NSPopUpButton *popUpMenu;
@property (weak) IBOutlet NSView *containerView;

@property (strong) Utilities *utility;
@property (strong) NSMutableArray *storeResponse;

@property (nonatomic) NSString *contentType;
@property (nonatomic) NSString *purchaseType;

@property (strong) AvailableProducts *availableProducts;
@property (strong) InvalidProductIdentifiers *invalidProductIdentifiers;
@property (strong) MessagesViewController *messageViewController;
@property (strong) PurchasesDetails *purchasesDetails;
@end

@implementation MainViewController
#pragma mark - Initializer

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self != nil) {
        _utility = [[Utilities alloc] init];
        _storeResponse = [NSMutableArray array];
        _contentType = PCSViewControllerNamesProducts;
        _purchaseType = PCSPurchasesPurchased;
    }
    return self;
}

#pragma mark - Instantiate View Controllers

-(AvailableProducts *)instantiateAvailableProductsWithData:(NSMutableArray *)data {
    AvailableProducts *controller = (AvailableProducts *)[self.storyboard instantiateControllerWithIdentifier:PCSViewControllerIdentifiersAvailableProducts];
    controller.data = data;
    return controller;
}

-(InvalidProductIdentifiers *)instantiateInvalidProductIdentifiersWithData:(NSMutableArray *)data {
    InvalidProductIdentifiers *controller = (InvalidProductIdentifiers *)[self.storyboard instantiateControllerWithIdentifier:PCSViewControllerIdentifiersInvalidProductIdentifiers];
    controller.data = data;
    return controller;
}

-(PurchasesDetails *)instantiatePurchasesDetailsWithData:(NSMutableArray *)data {
    PurchasesDetails *controller = (PurchasesDetails *)[self.storyboard instantiateControllerWithIdentifier:PCSViewControllerIdentifiersPurchases];
    controller.data = data;
    return controller;
}

-(MessagesViewController *)instantiateMessagesViewController {
    MessagesViewController *controller = (MessagesViewController *)[self.storyboard instantiateControllerWithIdentifier:PCSViewControllerIdentifiersMessages];
    return controller;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self disableUI];
    
    self.messageViewController = [self instantiateMessagesViewController];
    self.availableProducts = [self instantiateAvailableProductsWithData:[NSMutableArray array]];
    self.invalidProductIdentifiers = [self instantiateInvalidProductIdentifiersWithData:[NSMutableArray array]];
    self.purchasesDetails = [self instantiatePurchasesDetailsWithData:[NSMutableArray array]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleProductRequestNotification:)
                                                 name:PCSProductRequestNotification object:[StoreManager sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchaseNotification:)
                                                 name:PCSPurchaseNotification object:[StoreObserver sharedInstance]];
}

#pragma mark - Populate Pop-up Menu

/// The system uses this to update the UI with available products, invalid identifiers, purchases, or restored purchases.
- (IBAction)popUpMenuDidChangeValue:(NSPopUpButton *)sender {
    NSString *title = sender.titleOfSelectedItem;
    NSMutableArray *items = [NSMutableArray array];
    
    if ([title isEqualToString:PCSProductsAvailableProducts] || [title isEqualToString:PCSProductsInvalidIdentifiers] ) {
        Section *section = [self.utility parse:self.storeResponse forName:title];
        items = [section.elements copy];
    }
    
    if ([title isEqualToString:PCSProductsAvailableProducts]) {
        [self displayViewController:self.availableProducts withItems:items];
    } else if ([title isEqualToString:PCSProductsInvalidIdentifiers]){
        [self displayViewController:self.invalidProductIdentifiers withItems:items];
    } else if ([title isEqualToString:PCSPurchasesPurchased]) {
        self.utility.restoreWasCalled = NO;
    } else if ([title isEqualToString:PCSPurchasesRestored]) {
        self.utility.restoreWasCalled = YES;
    }
    
    if ([title isEqualToString:PCSPurchasesPurchased] || [title isEqualToString:PCSPurchasesRestored]) {
        NSArray *data = [NSArray arrayWithArray:self.utility.dataSourceForPurchasesUI];
        self.purchaseType = title;
        
        Section *section = [self.utility parse:data forName:title];
        [self.purchasesDetails reloadUIWithData:[section.elements copy]];
    }
}

/// Updates the pop-up menu with the given items and selects the item with the specified title.
-(void)reloadPopUpMenuWithItems:(NSArray *)items andSelectItemWithTitle:(NSString *)title {
    [self.popUpMenu removeAllItems];
    
    if (items.count > 0 ) {
        [self.popUpMenu addItemsWithTitles:items];
        [self.popUpMenu selectItemWithTitle:title];
    }
}

#pragma mark - Handle productRequest Notification

/// Updates the UI according to the product request notification result.
-(void)handleProductRequestNotification:(NSNotification *)notification {
    StoreManager *productRequestNotification = (StoreManager*)notification.object;
    PCSProductRequestStatus status = (PCSProductRequestStatus)productRequestNotification.status;
    NSString *selectedItem = PCSProductsInvalidIdentifiers;
    
    if (status == PCSStoreResponse) {
        self.contentType = PCSViewControllerNamesProducts;
        self.storeResponse = productRequestNotification.storeResponse;
        NSArray *menu = [self.storeResponse valueForKey:kSectionName];
        
        self.purchaseType = ((self.contentType == PCSViewControllerNamesPurchases) && self.utility.restoreWasCalled) ? PCSPurchasesRestored : PCSPurchasesPurchased;
        
        [self parseStoreResponseForName:PCSProductsInvalidIdentifiers AndDisplayViewController:self.invalidProductIdentifiers];
        
        if ([self parseStoreResponseForName:PCSProductsAvailableProducts AndDisplayViewController:self.availableProducts]) {
            selectedItem = PCSProductsAvailableProducts;
        }
        
        [self reloadPopUpMenuWithItems:menu andSelectItemWithTitle:selectedItem];
    } else if (status == PCSRequestFailed) {
        [self reloadViewController:PCSViewControllerNamesMessages withMessage:productRequestNotification.message];
    }
}

#pragma mark - Handle purchase Notification

/// Updates the UI according to the purchase request notification result.
-(void)handlePurchaseNotification:(NSNotification *)notification {
    StoreObserver *purchasesNotification = (StoreObserver *)notification.object;
    PCSPurchaseStatus status = (PCSPurchaseStatus)purchasesNotification.status;
    
    switch (status) {
        case PCSNoRestorablePurchases:
        case PCSPurchaseFailed:
        case PCSRestoreFailed:
            [self reloadViewController:PCSViewControllerNamesMessages withMessage:purchasesNotification.message];
            break;
        case PCSRestoreSucceeded: [self handleRestoredSucceededTransaction];
            break;
        default: break;
    }
}

#pragma mark - Handle Restored Transactions

/// Handles successful restored transactions. Switches to the Purchases view.
-(void)handleRestoredSucceededTransaction {
    self.utility.restoreWasCalled = YES;
    self.contentType = PCSViewControllerNamesPurchases;
    
    self.purchaseType = ((self.contentType == PCSViewControllerNamesPurchases) && self.utility.restoreWasCalled) ? PCSPurchasesRestored : PCSPurchasesPurchased;
    [self reloadViewController:PCSViewControllerNamesPurchases];
}

#pragma mark - Switching Between View Controllers

/// Adds a subview to the container.
-(void)addPrimaryViewController:(NSViewController *)viewController {
    [self addChildViewController:viewController];
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGRect newViewControllerFrame = viewController.view.frame;
    newViewControllerFrame.size.height = CGRectGetHeight(self.containerView.frame);
    newViewControllerFrame.size.width = CGRectGetWidth(self.containerView.frame);
    viewController.view.frame = newViewControllerFrame;
    [self.containerView addSubview:viewController.view];
    
    [NSLayoutConstraint activateConstraints:@[[viewController.view.topAnchor constraintEqualToAnchor: self.containerView.topAnchor],
                                              [viewController.view.bottomAnchor constraintEqualToAnchor: self.containerView.bottomAnchor],
                                              [viewController.view.leadingAnchor constraintEqualToAnchor: self.containerView.leadingAnchor],
                                              [viewController.view.trailingAnchor constraintEqualToAnchor: self.containerView.trailingAnchor]]];
}

/// Removes a subview from the container.
-(void)removePrimaryViewController:(NSViewController *)viewController {
    if (viewController != nil) {
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
}

/// Removes all subviews from the container.
-(void)removeAllPrimaryChildViewControllers {
    for (NSViewController *child in self.childViewControllers) {
        [self removePrimaryViewController:child];
    }
}

#pragma mark - Configure UI

/// Hides or shows a control.
-(void)hideControl:(NSControl *)control forStatus:(BOOL)status {
    if (self.viewLoaded) {
        control.hidden = status;
        [self.view layoutSubtreeIfNeeded];
    }
}

/// Hides the pop-up button and status message.
-(void)disableUI {
    if (self.viewLoaded) {
        self.popUpMenu.hidden = YES;
        [self.view layoutSubtreeIfNeeded];
    }
}

/// Displays the specified view controller with the given items.
- (void)displayViewController:(PrimaryViewController *)viewController withItems:(NSMutableArray *)items {
    [self removeAllPrimaryChildViewControllers];
    [self addPrimaryViewController:viewController];
    [viewController reloadUIWithData:items];
}

/// Parses the App Store response for a given view controller's data, then displays it.
-(BOOL)parseStoreResponseForName:(NSString *)name AndDisplayViewController:(PrimaryViewController *)viewController {
    Section *section = [self.utility parse:self.storeResponse forName:name];
    
    if ((section != nil) && (section.elements > 0)) {
        NSMutableArray *items = [section.elements copy];
        [self displayViewController:viewController withItems:items];
        return YES;
    }
    return NO;
}

/// Reloads the UI of the specified view controller.
-(void)reloadViewController:(NSString *)viewController {
    NSString *selectedItem;
    NSMutableArray *menu = [NSMutableArray array];
    [self disableUI];
    
    self.contentType = viewController;
    self.purchaseType = ((self.contentType == PCSViewControllerNamesPurchases) && self.utility.restoreWasCalled) ? PCSPurchasesRestored : PCSPurchasesPurchased;
    
    if ([viewController isEqualToString:PCSViewControllerNamesProducts]) {
        NSArray *identifiers = self.utility.identifiers;
        
        if (identifiers != nil) {
            [self hideControl:self.popUpMenu forStatus:NO];
            selectedItem = PCSProductsInvalidIdentifiers;
            [menu addObject:selectedItem];
            
            self.storeResponse = [NSMutableArray arrayWithObject:[[Section alloc] initWithName:PCSProductsInvalidIdentifiers elements:identifiers]];
            
            [self displayViewController:self.invalidProductIdentifiers withItems:[identifiers copy]];
            [[StoreManager sharedInstance] startProductRequestWithIdentifiers:identifiers];
        }
    } else if ([viewController isEqualToString:PCSViewControllerNamesPurchases] ) {
        NSArray *data = [NSArray arrayWithArray:self.utility.dataSourceForPurchasesUI];
        
        if (data.count > 0) {
            [self hideControl:self.popUpMenu forStatus:NO];
            selectedItem = self.purchaseType;
            menu = [data valueForKey:kSectionName];
            
            Section *section = [self.utility parse:data forName:selectedItem];
            
            if ((section != nil) && (section.elements.count > 0)) {
                [self displayViewController:self.purchasesDetails withItems:[section.elements copy]];
            }
        } else {
            NSString *message = [NSString stringWithFormat:@"%@\n%@", PCSMessagesNoPurchasesAvailable, PCSMessagesUseStoreRestore];
            [self reloadViewController:PCSViewControllerNamesMessages withMessage:message];
        }
    }
    
    if (menu.count > 0 && selectedItem != nil) {
        [self reloadPopUpMenuWithItems:menu andSelectItemWithTitle:selectedItem];
    }
}

/// Displays and reloads the Messages view controller with the specified message.
-(void)reloadViewController:(NSString *)viewController withMessage:(NSString*)message {
    [self removeAllPrimaryChildViewControllers];
    [self disableUI];
    
    self.contentType = viewController;
    self.purchaseType = PCSPurchasesPurchased;
    
    [self addPrimaryViewController:self.messageViewController];
    self.messageViewController.message = message;
}

#pragma mark - Memory Management

- (void)dealloc {
    // Unregister for StoreManager's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSProductRequestNotification object:[StoreManager sharedInstance]];
    
    // Unregister for StoreObserver's notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PCSPurchaseNotification object:[StoreObserver sharedInstance]];
}

@end

