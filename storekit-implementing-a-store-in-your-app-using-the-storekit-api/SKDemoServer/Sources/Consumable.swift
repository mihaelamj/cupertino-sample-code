/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model representing a Consumable In-App Purchase.
*/

import OSLog
import SwiftData

private let logger = Logger(subsystem: "SKDemoServer", category: "Consumable")

@Model
public final class Consumable: Codable, Identifiable {
    public typealias ProductID = String
    public typealias TransactionID = UInt64

    @Attribute(.unique) public private(set) var id: String
    public var ownedQuantity: UInt64
    public var finishedTransactionIDs: Set<TransactionID>

    init?(productID: ProductID) {
        guard productID.contains("consumable") else { return nil }
        if productID.contains("boosts") {
            self.id = "boosts"
        } else {
            self.id = productID
        }
        self.ownedQuantity = .zero
        self.finishedTransactionIDs = []
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.ownedQuantity = try container.decode(UInt64.self, forKey: .ownedQuantity)
        let finishedTransactionIDs = try container.decode([UInt64].self, forKey: .finishedTransactionIDs)
        self.finishedTransactionIDs = Set(finishedTransactionIDs)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownedQuantity, forKey: .ownedQuantity)
        try container.encode(Array(finishedTransactionIDs), forKey: .finishedTransactionIDs)
    }
}

private extension Consumable {
    private enum CodingKeys: String, CodingKey {
        case id
        case ownedQuantity
        case finishedTransactionIDs
    }
}
