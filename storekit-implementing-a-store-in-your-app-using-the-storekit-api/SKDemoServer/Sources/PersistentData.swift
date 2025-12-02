/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The persisted data.
*/

@preconcurrency import SwiftData

struct PersistentData {
    static let container = try! ModelContainer(for: schema)

    private static let schema = Schema([
        Consumable.self
    ])
}
