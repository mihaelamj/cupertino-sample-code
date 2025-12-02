/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Support for this app's store.
*/

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class Store {
    private let defaultsKey = "com.example.consumable count"

    public var consumableCount: Int {
        willSet {
            UserDefaults.standard.set(newValue, forKey: defaultsKey)
        }
    }
    public var boughtNonConsumable: Bool = false
    public var activeSubscription: String? = nil

    init() {
        // Note: If you delete transactions from the Manage Transaction window in Xcode,
        // you also need to manually reset state stored in User Defaults -- for example,
        // by running the following command in Terminal:
        // defaults delete com.example.apple-samplecode.StoreKitWorkflows
        self.consumableCount = UserDefaults.standard.integer(forKey: defaultsKey)  // Returns 0 on first app launch.

        // Because the tasks below capture 'self' in their closures, this object must be fully initialized before this point.
        Task(priority: .background) {
            // Finish any unfinished transactions -- for example, if the app was terminated before finishing a transaction.
            for await verificationResult in Transaction.unfinished {
                await handle(updatedTransaction: verificationResult)
            }

            // Fetch current entitlements for all product types except consumables.
            for await verificationResult in Transaction.currentEntitlements {
                await handle(updatedTransaction: verificationResult)
            }
        }
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                await handle(updatedTransaction: verificationResult)
            }
        }
    }

    private func handle(updatedTransaction verificationResult: VerificationResult<Transaction>) async {
        // The code below handles only verified transactions; handle unverified transactions based on your business model.
        guard case .verified(let transaction) = verificationResult else { return }

        if let _ = transaction.revocationDate {
            // Remove access to the product identified by `transaction.productID`.
            // `Transaction.revocationReason` provides details about the revoked transaction.
            guard let productID = ProductID(rawValue: transaction.productID) else {
                print("Unexpected product: \(transaction.productID).")
                return
            }

            switch productID {
            case .consumable:
                consumableCount -= 1
            case .consumablePack:
                consumableCount -= 10
            case .nonconsumable:
                boughtNonConsumable = false
            case .subscriptionMonthly, .subscriptionYearly, .subscriptionPremiumYearly:
                // In an app that supports Family Sharing, there might be another entitlement that still provides access to the subscription.
                activeSubscription = nil
            }
            await transaction.finish()
            return
        } else if let expirationDate = transaction.expirationDate, expirationDate < Date() {
            // In an app that supports Family Sharing, there might be another entitlement that still provides access to the subscription.
            activeSubscription = nil
            return
        } else {
            // Provide access to the product identified by transaction.productID.
            guard let productID = ProductID(rawValue: transaction.productID) else {
                print("Unexpected product: \(transaction.productID).")
                return
            }
            print("transaction ID \(transaction.id), product ID \(transaction.productID)")
            switch productID {
            case .consumable:
                consumableCount += 1
            case .consumablePack:
                consumableCount += 10
            case .nonconsumable:
                boughtNonConsumable = true
            case .subscriptionMonthly, .subscriptionYearly, .subscriptionPremiumYearly:
                // In an app that supports Family Sharing, there might be another entitlement that already provides access to the subscription.
                activeSubscription = transaction.productID
            }
            await transaction.finish()
            return
        }
    }
}
