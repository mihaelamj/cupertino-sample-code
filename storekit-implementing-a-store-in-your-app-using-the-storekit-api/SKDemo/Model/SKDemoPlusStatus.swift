/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The enumeration that defines the SKDemo+ user status.
*/

import OSLog
import StoreKit

private let logger = Logger(subsystem: "SKDemo", category: "SKDemoPlusStatus")

// Define the app's subscription entitlements by level of service, with the highest level of service first.
//
// The numerical-level value matches the subscription's level that you configure in
// the StoreKit configuration file or App Store Connect.
enum SKDemoPlusStatus: Int, CaseIterable, Comparable {
    case unsubscribed = 0
    case pro = 1
    case premium = 2
    case standard = 3

    init?(for product: Product) throws(SKDemoPlusStatusError) {
        // The product must be a subscription to have service entitlements.
        guard let subscription = product.subscription else { throw .invalidProduct }
        self.init(rawValue: subscription.groupLevel)
    }

    init(productID: Product.ID) throws(SKDemoPlusStatusError) {
        switch productID {
        case _ where ["plus.standard", "plus.standard.shared"].contains(productID):
            self = .standard
        case _ where ["plus.premium", "plus.premium.shared"].contains(productID):
            self = .premium
        case _ where ["plus.pro", "plus.pro.shared"].contains(productID):
            self = .pro
        case _:
            logger.error("""
            Failed to create an SKDemoPlusStatus for product ID \(productID)
            """)
            throw .invalidProductID
        }
    }

    public static func <(lhs: Self, rhs: Self) -> Bool {
        // Subscription-group levels are in descending order.
        return lhs.rawValue > rhs.rawValue
    }
}

enum SKDemoPlusStatusError: Error {
    case invalidProduct
    case invalidProductID
}
