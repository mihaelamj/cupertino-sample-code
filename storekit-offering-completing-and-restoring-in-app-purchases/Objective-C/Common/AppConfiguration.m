/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app configuration data.
*/

#import "AppConfiguration.h"

#pragma mark - Messages

#if TARGET_OS_IPHONE
NSString *const PCSMessagesCannotMakePayments = @"You don’t have authorization to make payments. There may be restrictions on your device for in-app purchases.";
#else
NSString *const PCSMessagesCannotMakePayments = @"In-app purchases aren’t allowed.";
#endif
NSString *const PCSMessagesDeferred = @"Allow the user to continue using your app.";
NSString *const PCSMessagesDeliverContent = @"Deliver content for";
NSString *const PCSMessagesEmptyResource = @"is empty. Update it with your product identifiers to retrieve product information.";
NSString *const PCSMessagesError = @"Error:";
NSString *const PCSMessagesFailed = @"failed.";
NSString *const PCSMessagesNoRestorablePurchases = @"There are no restorable purchases.";
NSString *const PCSMessagesOk = @"OK";
NSString *const PCSMessagesPurchaseOf = @"Purchase of";
NSString *const PCSMessagesPurchaseStatus = @"Purchase Status";
NSString *const PCSMessagesPreviouslyBought = @"You can only restore previously purchased non-consumable products and auto-renewable subscriptions.";
NSString *const PCSMessagesProductRequestStatus = @"Product Request Status";
NSString *const PCSMessagesRemove = @"was removed from the payment queue.";
NSString *const PCSMessagesResourceNotFound = @"Can't find resource file:";
NSString *const PCSMessagesRestorable = @"The payment queue has processed all restorable transactions.";
NSString *const PCSMessagesRestoreContent = @"Restore content for";
NSString *const PCSMessagesStatus = @"Status";
NSString *const PCSMessagesNoPurchasesAvailable = @"No purchases available.";
NSString *const PCSMessagesUseStoreRestore = @"Choose Store > Restore to restore your non-consumable products and auto-renewable subscriptions.";

#pragma mark - Notifications

NSString *const PCSProductRequestNotification = @"ProductRequestNotification";
NSString *const PCSPurchaseNotification = @"PurchaseNotification";
NSString *const PCSRestoredWasCalledNotification = @"restoredWasCalledNotification";

#pragma mark - Payment Transaction Details Labels

NSString *const PCSPaymentTransactionDetailsLabelsTransactionDate = @"Transaction Date";
NSString *const PCSPaymentTransactionDetailsLabelsTransactionIdentifier = @"Transaction ID";

#pragma mark - Payment Transaction Details Table

NSString *const PCSPaymentTransactionDetailsOriginalTransaction = @"ORIGINAL TRANSACTION";
NSString *const PCSPaymentTransactionDetailsProductIdentifier = @"PRODUCT IDENTIFIER";
NSString *const PCSPaymentTransactionDetailsTransactionIdentifier = @"TRANSACTION ID";
NSString *const PCSPaymentTransactionDetailsTransactionDate = @"TRANSACTION DATE";

#pragma mark - Products Table Header Section

#if TARGET_OS_OSX
NSString *const PCSProductsAvailableProducts = @"Available Products";
NSString *const PCSProductsInvalidIdentifiers = @"Invalid Product Identifiers";
#else
NSString *const PCSProductsAvailableProducts = @"AVAILABLE PRODUCTS";
NSString *const PCSProductsInvalidIdentifiers = @"INVALID PRODUCT IDENTIFIERS";
#endif

#pragma mark - Purchases Table Header Section

#if TARGET_OS_OSX
NSString *const PCSPurchasesPurchased = @"Purchased";
NSString *const PCSPurchasesRestored = @"Restored";
#else
NSString *const PCSPurchasesPurchased = @"PURCHASED";
NSString *const PCSPurchasesRestored = @"RESTORED";
#endif

#pragma mark - Resource File

NSString *const PCSProductIdsPlistName = @"ProductIds";
NSString *const PCSProductIdsPlistFileExtension = @"plist";

#pragma mark - View Controller Identifiers

NSString *const PCSViewControllerIdentifiersAvailableProducts = @"availableProducts";
NSString *const PCSViewControllerIdentifiersInvalidProductIdentifiers = @"invalidProductIdentifiers";
NSString *const PCSViewControllerIdentifiersMessages = @"messages";
NSString *const PCSViewControllerIdentifiersProducts = @"products";
NSString *const PCSViewControllerIdentifiersPurchases = @"purchases";

#pragma mark - View Controller Names

NSString *const PCSViewControllerNamesMessages = @"Messages";
NSString *const PCSViewControllerNamesProducts = @"Products";
NSString *const PCSViewControllerNamesPurchases = @"Purchases";

