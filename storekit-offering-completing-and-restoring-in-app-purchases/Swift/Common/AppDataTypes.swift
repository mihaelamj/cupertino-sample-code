/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience data structures.
*/

import Foundation

// MARK: - Transaction data

/// A structure that specifies the date and identifier of payment transactions.
struct TransactionContentLabels {
    static let transactionDate = "Transaction Date"
    static let transactionIdentifier = "Transaction ID"
}

// MARK: - Message

/// A structure of messages to display to users.
struct Messages {
    #if os (iOS)
    static let cannotMakePayments = "\(notAuthorized) \(installing)"
    #else
    static let cannotMakePayments = "In-app purchases aren’t allowed."
    #endif
    static let couldNotFind = "Can’t find resource file:"
    static let deferred = "Allow the user to continue using your app."
    static let deliverContent = "Deliver content for"
    static let emptyString = ""
    static let error = "Error: "
    static let failed = "failed."
    static let installing = "There may be restrictions on your device for in-app purchases."
    static let invalidIndexPath = "Invalid selected index path"
    static let noRestorablePurchases = "There are no restorable purchases.\n\(previouslyBought)"
    static let noPurchasesAvailable = "No purchases available."
    static let notAuthorized = "You don’t have authorization to make payments."
    static let okButton = "OK"
    static let previouslyBought = "You can only restore previously purchased non-consumable products and auto-renewable subscriptions."
    static let productRequestStatus = "Product Request Status"
    static let purchaseOf = "Purchase of"
    static let purchaseStatus = "Purchase Status"
    static let removed = "was removed from the payment queue."
    static let restorable = "The payment queue has processed all restorable transactions."
    static let restoreContent = "Restore content for"
    static let status = "Status"
    static let unableToInstantiateAvailableProducts = "Unable to instantiate an AvailableProducts."
    static let unableToInstantiateInvalidProductIds = "Unable to instantiate an InvalidProductIdentifiers."
    static let unableToInstantiateMessages = "Unable to instantiate a MessagesViewController."
    static let unableToInstantiateNavigationController = "Unable to instantiate a navigation controller."
    static let unableToInstantiateProducts = "Unable to instantiate a Products."
    static let unableToInstantiatePurchases = "Unable to instantiate a Purchases."
    static let unableToInstantiateSettings = "Unable to instantiate a Settings."
    static let unknownPaymentTransaction = "Unknown payment transaction case."
    static let unknownDestinationViewController = "Unknown destination view controller."
    static let unknownDetail = "Unknown detail row:"
    static let unknownPurchase = "No selected purchase."
    static let unknownSelectedSegmentIndex = "Unknown selected segment index: "
    static let unknownSelectedViewController = "Unknown selected view controller."
    static let unknownTabBarIndex = "Unknown tab bar index:"
    static let unknownToolbarItem = "Unknown selected toolbar item: "
    static let updateResource = "Update it with your product identifiers to retrieve product information."
    static let useStoreRestore = "Choose Store > Restore to restore your previously bought non-consumable products and auto-renewable subscriptions."
    static let viewControllerDoesNotExist = "The main content view controller doesn’t exist."
    static let windowDoesNotExist = "The window doesn’t exist."
}

// MARK: - Resource File

/// A structure that specifies the name and file extension of a resource file, which contains the product identifiers to query.
struct ProductIdentifiers {
    /// The name of the resource file containing the product identifiers.
    let name = "ProductIds"
    /// The filename extension of the resource file containing the product identifiers.
    let fileExtension = "plist"
}

// MARK: - Data Management

/// An enumeration of all the types of products and purchases.
enum SectionType: String, CustomStringConvertible {
    #if os (macOS)
    case availableProducts = "Available Products"
    case invalidProductIdentifiers = "Invalid Product Identifiers"
    case purchased = "Purchased"
    case restored = "Restored"
    #else
    case availableProducts = "AVAILABLE PRODUCTS"
    case invalidProductIdentifiers = "INVALID PRODUCT IDENTIFIERS"
    case purchased = "PURCHASED"
    case restored = "RESTORED"
    #endif
    case originalTransaction = "ORIGINAL TRANSACTION"
    case productIdentifier = "PRODUCT IDENTIFIER"
    case transactionDate = "TRANSACTION DATE"
    case transactionIdentifier = "TRANSACTION ID"
    
    var description: String {
        return self.rawValue
    }
}

/// A structure that represents a list of products and purchases.
struct Section {
    /// The system organizes products and purchases by category.
    var type: SectionType
    /// The list of products and purchases.
    var elements = [Any]()
}

// MARK: - View Controllers

/// A structure that specifies all the view controller identifiers.
struct ViewControllerIdentifiers {
    static let availableProducts = "availableProducts"
    static let invalidProductdentifiers = "invalidProductIdentifiers"
    static let messages = "messages"
    static let products = "products"
    static let purchases = "purchases"
}

/// An enumeration of view controller names.
enum ViewControllerNames: String, CustomStringConvertible {
    case messages = "Messages"
    case products = "Products"
    case purchases = "Purchases"
    
    var description: String {
        return self.rawValue
    }
}
