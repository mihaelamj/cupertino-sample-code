/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Business logic for purchasing and determining what In-App Purchases to merchandise throughout the app.
*/

import OSLog
import SKDemoServer
import StoreKit

private let logger = Logger(subsystem: "SKDemo", category: "Store")

public actor Store: ObservableObject {
    @MainActor
    public static let shared: Store = .init()

    @MainActor
    @Published
    public private(set) var products: [Product] = []

    @MainActor
    @Published
    public private(set) var error: StoreError?

    public func loadProducts() async {
        do {
            // Request products from the App Store using the identifiers Server makes available.
            let products = try await Product.products(for: Server.shared.productIDs)
            Task { @MainActor in
                self.products = products
            }
        } catch {
            logger.error("Failed product request from the App Store. \(error)")
        }
    }

    public func process(purchaseResult: sending Product.PurchaseResult) async {
        switch purchaseResult {
        case .success(let verificationResult):
            let unsafeTransaction = verificationResult.unsafePayloadValue
            logger.log("""
            Processing transaction ID \(unsafeTransaction.id) for \(unsafeTransaction.productID)
            """)

            let transaction: Transaction
            // Check whether the JWS passes StoreKit verification.
            switch verificationResult {
            case .verified(let t):
                // The result is verified. Return the unwrapped value.
                logger.debug("""
                Transaction ID \(t.id) for \(t.productID) is verified
                """)
                transaction = t
            case .unverified(let t, let error):
                // StoreKit parses the JWS, but it fails verification.
                // Log failure and ignore unverified transactions.
                logger.error("""
                Transaction ID \(t.id) for \(t.productID) is unverified: \(error)
                """)
                await updateError(.invalidTransaction)
                return
            }

            await CustomerEntitlements.shared.process(transaction: transaction)
        case _:
            return
        }
    }

    @MainActor
    private func updateError(_ error: StoreError) {
        self.error = error
    }
}

public enum StoreError: Error, Equatable {
    case invalidTransaction
}

extension Store {
    @MainActor
    var boosts: [Product] {
        products
            .filter { $0.id.contains("boosts") }
            .sorted { $0.price < $1.price }
    }

    @MainActor
    var fuel: [Product] {
        var products = products
            .filter { $0.id.contains("fuel") }
        
        let partition = products
            .partition { $0.id.contains("diesel") }
        
        return [
            products[..<partition]
                .sorted { $0.price < $1.price },
            products[partition...]
                .sorted { $0.price < $1.price }
        ]
            .flatMap { $0 }
    }

    static func productID(for car: Car) -> Product.ID? {
        switch car {
        case .sedan:
            nil
        case .suv:
            "nonconsumable.utilityvehicle"
        case .pickupTruck:
            "nonconsumable.pickuptruck"
        }
    }
}
