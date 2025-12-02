/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A mock implementation of the app's server.
*/

import OSLog
import SwiftData

private let logger = Logger(subsystem: "SKDemoServer", category: "Server")

// `Server` simulates a server for this app.
//
// It is good practice to vend from a server information such as the
// product IDs of In-App Purchases the client can merchandise, and
// the quantity of purchased consumables which have been already consumed
// by the customer, if any.
//
// For the sake of demonstrating an appropriate use of StoreKit APIs,
// store the consumed quantity of the purchased consumables on device.
@ModelActor
public actor Server: Observable {
    // MARK: - IDs

    @Published
    public private(set) var productIDs: [String] = []
    public nonisolated let skDemoPlusGroupID: String = "3F19ED53"

    private init() {
        guard let path = Bundle.module.path(forResource: "Products", ofType: "plist"),
              let plist = FileManager.default.contents(atPath: path),
              let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String] else {
            fatalError("Fail to find or parse Products.plist")
        }

        self.init(modelContainer: PersistentData.container)
        Task {
            await populateProductIDs(from: data)
        }
    }

    private func populateProductIDs(from data: [String: String]) {
        self.productIDs = Array(data.values)
    }

    // MARK: - API

    public static nonisolated let shared: Server = .init()

    public func consumable(for productID: String) async throws -> Data {
        // Fetch current consumable data.
        let descriptor = FetchDescriptor<Consumable>()
        let ownedConsumables = try modelContext.fetch(descriptor)

        // Find the Consumable reference for this productID; if it doesn't exist, create it.
        if let ownedConsumable = ownedConsumables.first(where: { productID.contains($0.id) }) {
            return try JSONEncoder().encode(ownedConsumable)
        } else {
            guard let newConsumable = Consumable(productID: productID) else {
                logger.error("""
                Failed to find or initialize Consumable for product ID: \(productID)
                """)
                throw ServerError.failedToCreateModel
            }
            try await insert(consumable: newConsumable)
            return try await consumable(for: productID)
        }
    }

    public func insert(consumable: sending Consumable) async throws {
        modelContext.insert(consumable)

        do {
            try modelContext.save()
        } catch {
            logger.error("Fail to save model context: \(error)")
            // Rollback the pending changes if the model context isn't updatable.
            modelContext.rollback()
            throw ServerError.failedToUpdateModelContext
        }
    }
}

public enum ServerError: Error {
    case failedToCreateModel
    case failedToUpdateModelContext
}
