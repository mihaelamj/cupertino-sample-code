/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the app.
*/

import OSLog
import SKDemoServer
import StoreKit
import SwiftUI

@main
struct SKDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .checkCustomerEntitlements()
                .loadProducts()
                .observeErrors()
        }
    }
}

// MARK: - Customer Entitlements

// A view modifier that checks the customer's current entitlements.
//
// Only use once in your app.
private struct CustomerEntitlementsViewModifier: ViewModifier {
    private let logger = Logger(subsystem: "SKDemo", category: "CustomerEntitlementsViewModifier")

    @ObservedObject private var customerEntitlements = CustomerEntitlements.shared

    @State private var skDemoPlusStatus: SKDemoPlusStatus?
    @State private var ownedCars: Set<Car> = []

    func body(content: Content) -> some View {
        content
            // Check the customer's current entitlements.
            .task { await checkCurrentUserState() }
            // Observe changes to the customer's entitlements.
            .task { await observeEntitlementUpdates() }
            // Observe updates to the user's status for SKDemo+.
            .onChange(of: customerEntitlements.subscriptionStatuses) { _, subscriptionStatuses in
                do {
                    self.skDemoPlusStatus = try transformStatuses(subscriptionStatuses[Server.shared.skDemoPlusGroupID])
                } catch {
                    logger.error("""
                    Fail to transform statuses for subscription group ID \(Server.shared.skDemoPlusGroupID): \(error)
                    """)
                    return
                }
            }
            .environment(\.skDemoPlusStatus, skDemoPlusStatus ?? .unsubscribed)
            // Observe updates to the user's owned cars.
            .onChange(of: customerEntitlements.ownedNonConsumables) { _, ownedNonConsumables in
                self.ownedCars = transformOwnedNonConsumables(ownedNonConsumables)
            }
            .environment(\.ownedCars, ownedCars)
    }

    private func checkCurrentUserState() async {
        // Check if there are any unfinished transactions.
        await CustomerEntitlements.shared.checkForUnfinishedTransactions()
        // Check if there are any current entitlements.
        await CustomerEntitlements.shared.checkForCurrentEntitlements()
        // Check current status.
        await CustomerEntitlements.shared.checkCurrentStatuses()
    }

    private func observeEntitlementUpdates() async {
        // Begin observing StoreKit transaction updates in case a
        // transaction happens on another device.
        await CustomerEntitlements.shared.observeTransactionUpdates()
        // Begin observing StoreKit status updates.
        await CustomerEntitlements.shared.observeStatusUpdates()
    }

    private func transformOwnedNonConsumables(_ ownedNonConsumables: Set<Product.ID>) -> Set<Car> {
        let ownedCars = ownedNonConsumables
            .compactMap {
                Car($0)
            }
        return Set(ownedCars).union([CustomerEntitlements.freeCar])
    }

    private func transformStatuses(_ subscriptionStatuses: [SubscriptionStatus]?) throws -> SKDemoPlusStatus? {
        return try subscriptionStatuses?.highestSubscriptionStatus.flatMap {
            try SKDemoPlusStatus(productID: $0.transaction.unsafePayloadValue.productID)
        }
    }
}

private extension View {
    func checkCustomerEntitlements() -> some View {
        modifier(CustomerEntitlementsViewModifier())
    }
}

extension EnvironmentValues {
    // Make globally accessible the user's status for SKDemo+ to always have the latest information
    // readily available.
    @Entry fileprivate(set) var skDemoPlusStatus: SKDemoPlusStatus = .unsubscribed
    // Make globally accessible the user's owned cars to always have the latest information
    // readily available.
    @Entry fileprivate(set) var ownedCars: Set<Car> = [CustomerEntitlements.freeCar]
}

// MARK: - Store

// A view modifier that requests products from the App Store.
//
// Only use this once in your app.
private struct ProductLoaderViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .task {
                await Store.shared.loadProducts()
            }
    }
}

private extension View {
    func loadProducts() -> some View {
        modifier(ProductLoaderViewModifier())
    }
}

// MARK: - Errors

// A view modifier that listens for errors encountered during purchases and entitlement checks.
//
// This only use once in your app.
private struct ErrorObserverViewModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var customerEntitlements = CustomerEntitlements.shared
    @ObservedObject private var store = Store.shared

    @State private var error: (any Error)?

    private var showErrorAlert: Binding<Bool> {
        Binding {
            error != nil
        } set: {
            guard !$0 else { return }
            error = nil
        }
    }

    @ViewBuilder
    private var errorAlertActionView: some View {
        Button("Restore Purchases", role: .destructive) {
            Task {
                try await AppStore.sync()
            }
        }
        Button("OK", role: .cancel) {
            dismiss()
        }
    }

    private var errorAlertMessageView: some View {
        Text(verbatim: "Contact the developer for more information.")
    }

    func body(content: Content) -> some View {
        content
            // Observe errors encountered while checking customer entitlements.
            .onChange(of: customerEntitlements.error) { _, error in
                switch error {
                case .some(.invalidTransaction):
                    self.error = error
                case _:
                    return
                }
            }
            // Observe errors encountered during purchases.
            .onChange(of: store.error) { _, error in
                switch error {
                case .some(.invalidTransaction):
                    self.error = error
                case _:
                    return
                }
            }
            .alert(
                "An error occurred while checking your purchase history.",
                isPresented: showErrorAlert,
                actions: { errorAlertActionView },
                message: { errorAlertMessageView }
            )
    }
}

private extension View {
    func observeErrors() -> some View {
        modifier(ErrorObserverViewModifier())
    }
}
