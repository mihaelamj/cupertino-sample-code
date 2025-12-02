/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Business logic for the customer's entitlements.
*/

import OSLog
import SKDemoServer
import StoreKit

private let logger = Logger(subsystem: "SKDemo", category: "CustomerEntitlements")

public actor CustomerEntitlements: ObservableObject {

    private var transactionUpdatesTask: Task<Void, any Error>?
    private var statusUpdatesTask: Task<Void, any Error>?

    deinit {
        transactionUpdatesTask?.cancel()
        statusUpdatesTask?.cancel()
    }

    // MARK: - API

    @MainActor
    public static let shared: CustomerEntitlements = .init()

    @MainActor
    @Published
    public private(set) var ownedNonConsumables: Set<Product.ID> = []

    @MainActor
    @Published
    public private(set) var subscriptionStatuses: [SubscriptionGroupID: [SubscriptionStatus]] = [:]

    @MainActor
    @Published
    public private(set) var error: CustomerEntitlementsError?

    public func process(transaction: Transaction) async {
        // Only handle consumables and non consumables here. Check the subscription status each time
        // before unlocking a premium subscription feature.
        switch transaction.productType {
        case .nonConsumable:
            await processNonConsumableTransaction(transaction)
        case .consumable:
            await processConsumableTransaction(transaction)
        case _:
            // Finish the transaction. Grant access to the subscription based on the subscription status.
            await transaction.finish()
        }
    }

    // MARK: Transactions

    public func observeTransactionUpdates() {
        transactionUpdatesTask = Task { [weak self] in
            logger.debug("Observing transaction updates")
            for await update in Transaction.updates {
                guard let self else { return }
                guard let transaction = await unwrapVerificationResult(update) else { continue }
                await self.process(transaction: transaction)
            }
        }
    }

    public func checkForCurrentEntitlements() async {
        logger.debug("Checking for current entitlements")
        for await transaction in Transaction.currentEntitlements {
            guard let transaction = await unwrapVerificationResult(transaction) else {
                logger.error("Encountered error while checking for current entitlements")
                return
            }
            logger.log("""
            Processing current entitlement \(transaction.id) for \
            \(transaction.productID)
            """)
            Task.detached(priority: .background) {
                await self.process(transaction: transaction)
            }
        }
        logger.debug("Finished checking for current entitlements")
    }

    public func checkForUnfinishedTransactions() async {
        logger.debug("Checking for unfinished transactions")
        for await transaction in Transaction.unfinished {
            guard let transaction = await unwrapVerificationResult(transaction) else {
                logger.error("Encountered error while checking for unfinished transactions")
                return
            }
            logger.log("""
            Processing unfinished transaction ID \(transaction.id) for \
            \(transaction.productID)
            """)
            Task.detached(priority: .background) {
                await self.process(transaction: transaction)
            }
        }
        logger.debug("Finished checking for unfinished transactions")
    }

    // MARK: Statuses

    public func observeStatusUpdates() {
        statusUpdatesTask = Task { [weak self] in
            logger.debug("Observing status updates")
            for await status in SubscriptionStatus.updates {
                guard let self,
                      let transaction = await unwrapVerificationResult(status.transaction),
                      let subscriptionGroupID = transaction.subscriptionGroupID
                else {
                    continue
                }

                let updatedStatuses: [SubscriptionStatus]
                let currentStatuses = await self.subscriptionStatuses[subscriptionGroupID]
                if let currentStatuses {
                    if let currentStatus = currentStatuses.first(where: {
                        $0.transaction.unsafePayloadValue.ownershipType == transaction.ownershipType
                    }) {
                        updatedStatuses = currentStatuses.filter { $0 != currentStatus } + [status]
                    } else {
                        updatedStatuses = currentStatuses + [status]
                    }
                } else {
                    updatedStatuses = [status]
                }

                await self.updateSubscriptionStatuses(for: subscriptionGroupID, statuses: updatedStatuses)
            }
        }
    }

    public func checkCurrentStatuses() async {
        logger.debug("Checking current statuses")
        for await (subscriptionGroupID, statuses) in SubscriptionStatus.all {
            await updateSubscriptionStatuses(for: subscriptionGroupID, statuses: statuses)
        }
        logger.debug("Finished checking current statuses")
    }

    // MARK: - Private Helpers

    private func processConsumableTransaction(_ transaction: Transaction) async {
        guard transaction.productType == .consumable else {
            logger.error("""
            Failed to process transaction with ID: \(transaction.id);
            expected consumable product type, got \(transaction.productType.rawValue)
            """)
            return
        }

        let consumable: Consumable
        do {
            let data = try await Server.shared.consumable(for: transaction.productID)
            consumable = try JSONDecoder().decode(Consumable.self, from: data)
        } catch {
            logger.error("""
            Failed to retrieve owned consumable data \(error)
            """)
            await updateError(.failedToFetchPersistedData)
            return
        }

        guard !consumable.finishedTransactionIDs.contains(transaction.id) else {
            logger.error("""
            Ignoring transaction ID \(transaction.id) for \
            \(transaction.productID) because it is already processed it.
            """)
            return
        }

        var quantity: UInt64 {
            if transaction.productID.contains("boosts"),
               let quantityString = transaction.productID.components(separatedBy: ".").last,
               let quantity = UInt64(quantityString) {
                return quantity
            } else {
                return 1
            }
        }
        let delta: UInt64 = quantity * UInt64(transaction.purchasedQuantity)
        if transaction.revocationDate == nil, transaction.revocationReason == nil {
            consumable.ownedQuantity += delta

            logger.log("""
            Added \(delta) \(consumable.id)(s) from transaction ID: \
            \(transaction.id). New total quantity: \(consumable.ownedQuantity)
            """)
        } else {
            consumable.ownedQuantity -= delta

            logger.log("""
            Removed \(delta) \(consumable.id)(s) because transaction ID \
            \(transaction.id) was revoked due to \
            \(transaction.revocationReason?.localizedDescription ?? "unknown"). \
            New total quantity: \(consumable.ownedQuantity).
            """)
        }

        consumable.finishedTransactionIDs.insert(transaction.id)
        do {
            try await Server.shared.insert(consumable: consumable)
        } catch {
            logger.error("""
            Failed to update persisted data \(error)
            """)
            await updateError(.failedToUpdatePersistedData)
            return
        }

        // Finish the transaction after granting the user content.
        await transaction.finish()

        logger.debug("""
        Finished transaction ID \(transaction.id) for: \
        \(transaction.productID)
        """)
    }

    private func processNonConsumableTransaction(_ transaction: Transaction) async {
        guard transaction.productType == .nonConsumable else {
            logger.error("""
            Failed to process transaction with ID: \(transaction.id);
            expected nonConsumable product type, got \(transaction.productType.rawValue)
            """)
            return
        }

        if transaction.revocationDate == nil, transaction.revocationReason == nil {
            logger.log("""
            Added \(transaction.productID) from transaction ID: \
            \(transaction.id).
            """)

            await insertNonConsumable(productID: transaction.productID)
        } else {
            logger.log("""
            Removed \(transaction.productID) because transaction ID \
            \(transaction.id) was revoked due to \
            \(transaction.revocationReason?.localizedDescription ?? "unknown").
            """)

            await removeNonConsumable(productID: transaction.productID)
        }

        // Finish the transaction after granting the user content.
        await transaction.finish()

        logger.debug("""
        Finished transaction ID \(transaction.id) for: \
        \(transaction.productID)
        """)
    }

    private func unwrapVerificationResult(
        _ verificationResult: VerificationResult<Transaction>
    ) async -> Transaction? {
        // Send the transaction to your server to validate the JWS. Because this is just a demonstration,
        // use StoreKit's automatic validation.
        switch verificationResult {
        case .verified(let t):
            logger.debug("""
            Transaction ID \(t.id) for \(t.productID) is verified
            """)
            return t
        case .unverified(let t, let error):
            // Log failure and ignore unverified transactions.
            logger.error("""
            Transaction ID \(t.id) for \(t.productID) is unverified: \(error)
            """)
            await updateError(.invalidTransaction)
            return nil
        }
    }

    @MainActor
    private func insertNonConsumable(productID: Product.ID) {
        ownedNonConsumables.insert(productID)
    }

    @MainActor
    private func removeNonConsumable(productID: Product.ID) {
        ownedNonConsumables.remove(productID)
    }

    @MainActor
    private func updateSubscriptionStatuses(for subscriptionGroupID: String, statuses: [SubscriptionStatus]) {
        self.subscriptionStatuses[subscriptionGroupID] = statuses
    }

    @MainActor
    private func updateError(_ error: CustomerEntitlementsError) {
        self.error = error
    }
}

public enum CustomerEntitlementsError: Error, Equatable {
    case invalidTransaction
    case failedToFetchPersistedData
    case failedToUpdatePersistedData
}

extension CustomerEntitlements {
    // The sedan comes free with the app.
    static var freeCar: Car { .sedan }
}

extension Sequence where Element == SubscriptionStatus {
    // There may be multiple statuses for different family members, because this app supports Family Sharing.
    // The subscriber is entitled to service for the status with the highest level of service.
    var highestSubscriptionStatus: SubscriptionStatus? {
        get throws {
            try self.max { lhs, rhs in
                let lhsStatus = try SKDemoPlusStatus(productID: lhs.transaction.unsafePayloadValue.productID)
                let rhsStatus = try SKDemoPlusStatus(productID: rhs.transaction.unsafePayloadValue.productID)
                return lhsStatus < rhsStatus
            }
        }
    }
}
