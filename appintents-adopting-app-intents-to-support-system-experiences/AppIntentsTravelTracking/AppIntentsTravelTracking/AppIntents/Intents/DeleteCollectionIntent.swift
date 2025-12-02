/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to delete a landmark collection.
*/

import AppIntents
import SwiftUI

struct DeleteCollectionIntent: UndoableIntent {

    static let title: LocalizedStringResource = "Delete Collection"

    @Dependency var modelData: ModelData

    @Parameter
    var collection: CollectionEntity

    func perform() async throws -> some IntentResult & ReturnsValue<CollectionEntity?> {

        // Confirm deletion...
        try await requestConfirmation(
            actionName: .custom(
                acceptLabel: "Delete",
                acceptAlternatives: [],
                denyLabel: "Cancel",
                denyAlternatives: [],
                destructive: true
            ),
            dialog: "Would you like to delete \(collection.name)?"
        )

        await undoManager?.registerUndo(withTarget: modelData) { modelData in
            modelData.restoreCollection(collection)
        }
        await undoManager?.setActionName("Delete \(collection.name)")

        // Delete collection...
        try await modelData.deleteCollection(collection)
        return .result(value: nil)
    }
}

